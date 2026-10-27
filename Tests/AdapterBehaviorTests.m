#import "FakeSDK.h"
#import "OSETCustomerGmSplashAdapter.h"
#import "OSETCustomerGmInterstitialAdapter.h"
#import "OSETCustomerGmRewardAdapter.h"
#import "OSETCustomerGmNativeAdapter.h"
#import "OSETGmAdapterSupport.h"

@interface NSObject (TestCallbacks)
- (void)didReceiveBidResult:(BUMMediaBidResult *)result;
- (BUMMediatedAdStatus)mediatedAdStatus;
@end
@interface LegacyAd : OSETBaseAd
@end
@implementation LegacyAd
- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(reportBiddingWinWithInfo:) || selector == @selector(reportBiddingLossWithInfo:)) { return NO; }
    return [super respondsToSelector:selector];
}
@end
@interface ThrowingBidResult : BUMMediaBidResult
@end
@implementation ThrowingBidResult
- (BOOL)win { @throw [NSException exceptionWithName:@"Probe" reason:@"unavailable getter" userInfo:nil]; }
@end

static NSUInteger checks;
#define CHECK(condition, label) do { checks++; if (!(condition)) { fprintf(stderr, "FAIL: %s\n", label); exit(1); } } while (0)
static BUMMediaBidResult *Result(BOOL win, NSInteger price, id origin) {
    BUMMediaBidResult *result = [BUMMediaBidResult new];
    result.win = win; result.winnerPrice = price; result.originNativeAdData = origin;
    return result;
}
static NSError *Failure(void) { return [NSError errorWithDomain:@"test" code:1 userInfo:nil]; }
static GMBridgeSpy *Attach(id adapter) { GMBridgeSpy *bridge = [GMBridgeSpy new]; [adapter setBridge:bridge]; return bridge; }

static void CheckBidding(void) {
    CHECK([OSETGmLoadingExt(123)[BUMMediaAdLoadingExtECPM] isEqual:@"123"], "price is a decimal string");
    CHECK([OSETGmLoadingExt(0)[BUMMediaAdLoadingExtECPM] isEqual:@"0"], "zero price remains a string");
    CHECK(OSETGmLoadingExt(-1).count == 0, "unknown price is omitted");
    OSETBaseAd *ad = [OSETBaseAd new];
    OSETGmReportBidResult(ad, Result(YES, 180, nil));
    CHECK([ad.reports.lastObject[@"info"][@"biddingPrice"] isEqual:@180], "winning price forwarded");
    OSETGmReportBidResult(ad, Result(NO, 900, nil));
    CHECK(ad.reports.lastObject[@"info"][@"biddingPrice"] == nil, "loss does not report winner price as own bid");
    OSETGmReportBidResult(ad, Result(YES, 0, nil));
    CHECK(ad.reports.lastObject[@"info"][@"biddingPrice"] == nil, "nonpositive winning price omitted");
    OSETGmReportBidResult(ad, Result(YES, -1, nil));
    CHECK(ad.reports.lastObject[@"info"][@"biddingPrice"] == nil, "negative winning price omitted");
    OSETGmReportBidResult(ad, Result(YES, 180, nil));
    CHECK(ad.reports.count == 5, "each legal callback is forwarded without adapter deduplication");
    OSETGmReportBidResult(ad, (id)[NSNull null]);
    OSETGmReportBidResult(ad, [ThrowingBidResult new]);
    OSETGmReportBidResult((id)[NSNull null], Result(YES, 1, nil));
    CHECK(ad.reports.count == 5, "malformed objects and throwing getters safely skipped");
    LegacyAd *legacy = [LegacyAd new];
    OSETGmReportBidResult(legacy, Result(YES, 1, nil));
    OSETGmReportBidResult(legacy, Result(NO, 1, nil));
    CHECK(legacy.reports.count == 0, "legacy SDK without reporting methods is supported");
    dispatch_semaphore_t queued = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        OSETGmReportBidResult(ad, Result(YES, 230, nil));
        dispatch_semaphore_signal(queued);
    });
    CHECK(dispatch_semaphore_wait(queued, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0, "background callback enqueued");
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:2];
    while (ad.reports.count < 6 && deadline.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    CHECK(ad.reports.count == 6 && [ad.reports.lastObject[@"main"] boolValue], "background reporting delivered on main thread");
}

static void CheckFullScreen(void) {
    OSETCustomerGmRewardAdapter *reward = [OSETCustomerGmRewardAdapter new];
    GMBridgeSpy *bridge = Attach(reward);
    CHECK(![reward showAdFromRootViewController:bridge.vc parameter:@{}], "unloaded reward cannot show");
    CHECK([bridge count:@"reward.showFail"] == 1 && [bridge count:@"reward.loadFail"] == 0, "reward rejects via show failure");
    [reward loadRewardedVideoAdWithSlotID:@"reward" andParameter:@{BUMAdLoadingParamRVUserID: @"u1"}];
    OSETRewardVideoAd *ad = [reward valueForKey:@"rewardVideoAd"];
    CHECK([ad.userId isEqual:@"u1"], "reward reads official user ID parameter");
    ad.eCPM = 321;
    [(id<OSETRewardVideoAdDelegate>)reward rewardVideoDidReceiveSuccess:ad slotId:@"reward"];
    CHECK([bridge.lastExt[BUMMediaAdLoadingExtECPM] isEqual:@"321"], "reward loading price string");
    [reward didReceiveBidResult:Result(YES, 321, nil)];
    [reward didReceiveBidResult:Result(NO, 800, nil)];
    CHECK(ad.reports.count == 2, "reward reports both bid outcomes without unsafe logging");
    ad.valid = NO;
    CHECK([reward mediatedAdStatus].valid == BUMMediatedAdStatusValueDeny, "expired reward status denied");
    ad.valid = YES;
    CHECK([reward mediatedAdStatus].valid == BUMMediatedAdStatusValueSure, "valid reward status accepted");
    CHECK([reward showAdFromRootViewController:bridge.vc parameter:@{}], "valid reward show accepted");
    [(id<OSETRewardVideoAdDelegate>)reward rewardVideoLoadToFailed:ad error:Failure()];
    CHECK([bridge count:@"reward.showFail"] == 2 && [bridge count:@"reward.loadFail"] == 0, "reward SDK failure after show is a show failure");
    [reward loadRewardedVideoAdWithSlotID:@"reward2" andParameter:@{}];
    CHECK(ad.delegate == nil, "old reward delegate detached before reload");
    [(id<OSETRewardVideoAdDelegate>)reward rewardVideoLoadToFailed:nil error:Failure()];
    CHECK([bridge count:@"reward.loadFail"] == 1, "reward SDK loading failure preserved");

    OSETCustomerGmInterstitialAdapter *interstitial = [OSETCustomerGmInterstitialAdapter new];
    bridge = Attach(interstitial);
    CHECK(![interstitial showAdFromRootViewController:bridge.vc parameter:@{}], "unloaded interstitial cannot show");
    CHECK([bridge count:@"interstitial.showFail"] == 1 && [bridge count:@"interstitial.loadFail"] == 0, "interstitial rejects via show failure");
    [interstitial loadInterstitialAdWithSlotID:@"interstitial" andSize:CGSizeZero parameter:@{}];
    OSETInterstitialAd *interstitialAd = [interstitial valueForKey:@"interstitialAd"];
    interstitialAd.eCPM = 456;
    [(id<OSETInterstitialAdDelegate>)interstitial interstitialDidReceiveSuccess:interstitialAd slotId:@"interstitial"];
    CHECK([bridge.lastExt[BUMMediaAdLoadingExtECPM] isEqual:@"456"], "interstitial loading price string");
    [interstitial didReceiveBidResult:Result(YES, 456, nil)];
    CHECK(interstitialAd.reports.count == 1, "interstitial bid result forwarded");
    CHECK([interstitial showAdFromRootViewController:bridge.vc parameter:@{}], "valid interstitial show accepted");
    [(id<OSETInterstitialAdDelegate>)interstitial interstitialLoadToFailed:interstitialAd error:Failure()];
    CHECK([bridge count:@"interstitial.showFail"] == 2 && [bridge count:@"interstitial.loadFail"] == 0, "interstitial SDK show failure mapped correctly");
}

static void CheckSplash(void) {
    OSETCustomerGmSplashAdapter *adapter = [OSETCustomerGmSplashAdapter new];
    GMBridgeSpy *bridge = Attach(adapter);
    UIView *bottom = [UIView new];
    [adapter loadSplashAdWithSlotID:@"splash" andParameter:@{BUMAdLoadingParamSPCustomBottomView: bottom}];
    OSETSplashAd *ad = [adapter valueForKey:@"splashAd"];
    ad.eCPM = 111;
    [(id<OSETSplashAdDelegate>)adapter splashDidReceiveSuccess:ad slotId:@"splash"];
    CHECK([bridge.lastExt[BUMMediaAdLoadingExtECPM] isEqual:@"111"], "splash loading price string");
    [adapter didReceiveBidResult:Result(YES, 111, nil)];
    CHECK(ad.reports.count == 1, "splash bid result forwarded");
    UIWindow *window = [UIWindow new];
    [adapter showSplashAdInWindow:window parameter:@{}];
    CHECK(ad.shownWindow == window, "splash uses show-time window");
    CHECK([bridge count:@"splash.visible"] == 0, "show call does not fabricate exposure");
    [(id<OSETSplashAdDelegate>)adapter splashAdExposured:ad];
    [(id<OSETSplashAdDelegate>)adapter splashAdExposured:ad];
    CHECK([bridge count:@"splash.visible"] == 1, "actual splash exposure forwarded once");
    [adapter dismissSplashAd];
    [adapter dismissSplashAd];
    CHECK(ad.dismissCount == 1 && ad.delegate == nil && bottom.removed, "dismiss invokes SDK interceptor once and detaches resources");
    CHECK([adapter valueForKey:@"splashAd"] == nil, "dismiss releases held splash object");
    [(id<OSETSplashAdDelegate>)adapter splashAdExposured:ad];
    [(id<OSETSplashAdDelegate>)adapter splashDidClose:ad];
    [(id<OSETSplashAdDelegate>)adapter splashLoadToFailed:ad error:Failure()];
    CHECK([bridge count:@"splash.visible"] == 1 && [bridge count:@"splash.close"] == 0 && [bridge count:@"splash.loadFail"] == 0, "late splash callbacks ignored after external dismiss");
    [adapter loadSplashAdWithSlotID:@"splash2" andParameter:@{}];
    [adapter showSplashAdInWindow:window parameter:@{}];
    [(id<OSETSplashAdDelegate>)adapter splashAdExposuredToFailed:nil error:Failure()];
    [(id<OSETSplashAdDelegate>)adapter splashAdExposured:nil];
    CHECK([bridge count:@"splash.showFail"] == 1 && [bridge count:@"splash.visible"] == 1, "asynchronous splash show failure does not report exposure");
    [adapter loadSplashAdWithSlotID:@"splash3" andParameter:@{}];
    [adapter showSplashAdInWindow:window parameter:@{}];
    [(id<OSETSplashAdDelegate>)adapter splashLoadToFailed:nil error:Failure()];
    CHECK([bridge count:@"splash.showFail"] == 2 && [bridge count:@"splash.loadFail"] == 0, "load-style SDK callback after show maps to show failure");
}

static void CheckNative(void) {
    OSETCustomerGmNativeAdapter *adapter = [OSETCustomerGmNativeAdapter new];
    GMBridgeSpy *bridge = Attach(adapter);
    [(id<OSETNativeAdDelegate>)adapter nativeExpressAdDidExposured:[UIView new]];
    CHECK([bridge count:@"native.visible"] == 0, "exposure before a successful load is ignored");
    [adapter loadNativeAdWithSlotID:@"native" andSize:CGSizeZero imageSize:CGSizeZero parameter:@{}];
    OSETNativeAd *ad = [adapter valueForKey:@"nativeAd"];
    CHECK(ad.viewController == bridge.vc, "native uses real presenting controller");
    OSETBaseView *a = [OSETBaseView new], *b = [OSETBaseView new];
    a.eCPM = 100; b.eCPM = 200;
    __weak id weakAdapter = adapter;
    bridge.onNativeLoad = ^{ [weakAdapter didReceiveBidResult:Result(YES, 200, b)]; };
    [(id<OSETNativeAdDelegate>)adapter nativeExpressAdLoadSuccessWithNative:ad nativeExpressViews:@[a, [NSNull null], b]];
    bridge.onNativeLoad = nil;
    CHECK(bridge.views.count == 2 && bridge.exts.count == 2, "native filters invalid entries while preserving view-price alignment");
    CHECK([bridge.exts[1][BUMMediaAdLoadingExtECPM] isEqual:@"200"], "native loading price string");
    CHECK(a.reports.count == 0 && b.reports.count == 1, "reentrant native result attributed to correct view");
    [adapter didReceiveBidResult:Result(NO, 1000, b)];
    CHECK(b.reports.count == 2, "native loss forwarded to identified view");
    [adapter didReceiveBidResult:Result(YES, 300, nil)];
    [adapter didReceiveBidResult:Result(YES, 300, [NSNull null])];
    [adapter didReceiveBidResult:Result(YES, 300, [OSETBaseView new])];
    CHECK(a.reports.count == 0 && b.reports.count == 2, "ambiguous and foreign native results skipped");
    UIView *child = [UIView new]; child.superview = b;
    [(id<OSETNativeAdDelegate>)adapter nativeExpressAdDidExposured:child];
    CHECK(bridge.visibleView == b, "native exposure uses original loaded view");
    [(id<OSETNativeAdDelegate>)adapter nativeExpressAdDidExposured:[UIView new]];
    CHECK([bridge count:@"native.visible"] == 1, "unknown native view does not produce exposure");
    [adapter unregisterClickableViewsForNativeAd:b];
    CHECK([adapter respondsToSelector:@selector(unregisterClickableViewsForNativeAd:)], "required unregister selector implemented");
    [(id<OSETNativeAdDelegate>)adapter nativeExpressAdLoadSuccessWithNative:ad nativeExpressViews:@[a]];
    [adapter didReceiveBidResult:Result(YES, 100, nil)];
    [adapter didReceiveBidResult:Result(YES, 100, nil)];
    CHECK(a.reports.count == 2, "single-view native fallback forwards each valid callback");
}

int main(void) {
    @autoreleasepool {
        CheckBidding(); CheckFullScreen(); CheckSplash(); CheckNative();
        printf("PASS: %lu adapter behavior checks (controlled SDK doubles)\n", (unsigned long)checks);
    }
    return 0;
}
