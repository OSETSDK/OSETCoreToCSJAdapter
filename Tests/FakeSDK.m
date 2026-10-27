#import "FakeSDK.h"
#import <objc/runtime.h>
@implementation UIView
- (void)removeFromSuperview { self.removed = YES; self.superview = nil; }
@end
@implementation UIViewController
- (instancetype)init { if ((self = [super init])) { _view = [UIView new]; } return self; }
@end
@implementation UIWindow
@end
@implementation UIApplication
+ (instancetype)sharedApplication { static UIApplication *app; static dispatch_once_t once; dispatch_once(&once, ^{ app = [UIApplication new]; }); return app; }
@end
const BUMMediatedAdStatus BUMMediatedAdStatusUnknown = {0, 0, 0};
NSString *const BUMMediaAdLoadingExtECPM = @"ecpm";
NSString *const BUMAdLoadingParamSPCustomBottomView = @"bottomView";
NSString *const BUMAdLoadingParamRVUserID = @"rewardUserId";
@implementation BUMMediaBidResult
@end
@implementation BUMAdapterRewardAdInfo
@end
@implementation NSObject (GMTestBridgeStorage)
static char bridgeKey;
- (id<GMTestBridge>)bridge { return objc_getAssociatedObject(self, &bridgeKey); }
- (void)setBridge:(id<GMTestBridge>)bridge { objc_setAssociatedObject(self, &bridgeKey, bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
@end
// Deliberately absent from FakeSDK.h: adapters must compile without new SDK declarations.
#define RECORD_BID_METHODS \
- (void)reportBiddingWinWithInfo:(NSDictionary *)info { [self.reports addObject:@{@"win": @YES, @"info": info, @"main": @([NSThread isMainThread])}]; } \
- (void)reportBiddingLossWithInfo:(NSDictionary *)info { [self.reports addObject:@{@"win": @NO, @"info": info, @"main": @([NSThread isMainThread])}]; }
@implementation OSETBaseAd
- (instancetype)init { if ((self = [super init])) { _valid = YES; _reports = [NSMutableArray array]; } return self; }
- (BOOL)isAdValid { return self.valid; }
RECORD_BID_METHODS
@end
@implementation OSETBaseView
- (instancetype)init { if ((self = [super init])) { _reports = [NSMutableArray array]; } return self; }
RECORD_BID_METHODS
@end
@implementation OSETSplashAd
- (instancetype)initWithSlotId:(NSString *)slotID window:(UIWindow *)window bottomView:(UIView *)bottomView { return [super init]; }
- (void)loadSplashAd {}
- (void)showSplashAdWithWindow:(UIWindow *)window bottomView:(UIView *)bottomView { self.shownWindow = window; }
- (void)interceptSplashadView { self.dismissCount++; }
@end
@implementation OSETInterstitialAd
- (instancetype)initWithSlotId:(NSString *)slotID { return [super init]; }
- (void)loadInterstitialAdData {}
- (void)showInterstitialFromRootViewController:(UIViewController *)vc {}
@end
@implementation OSETRewardVideoAd
- (instancetype)initWithSlotId:(NSString *)slotID withUserId:(NSString *)userID { if ((self = [super init])) { _userId = userID; } return self; }
- (void)loadRewardAdData {}
- (void)showRewardFromRootViewController:(UIViewController *)vc {}
@end
@implementation OSETNativeAd
- (instancetype)initWithSlotId:(NSString *)slotID size:(CGSize)size rootViewController:(UIViewController *)vc { if ((self = [super init])) { _viewController = vc; } return self; }
- (void)loadAdData {}
@end
@implementation GMBridgeSpy
- (instancetype)init { if ((self = [super init])) { _events = [NSMutableArray array]; _vc = [UIViewController new]; _vc.view.window = [UIWindow new]; } return self; }
- (NSUInteger)count:(NSString *)name { return [[self.events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", name]] count]; }
- (UIViewController *)viewControllerForPresentingModalView { return self.vc; }
#define EVENT_METHOD(selector, name) - (void)selector:(id)ad { [self.events addObject:name]; }
#define EXT_METHOD(selector, name) - (void)selector:(id)ad didLoadWithExt:(NSDictionary *)ext { self.lastExt = ext; [self.events addObject:name]; }
#define LOAD_FAIL(selector, name) - (void)selector:(id)ad didLoadFailWithError:(NSError *)error ext:(NSDictionary *)ext { [self.events addObject:name]; }
#define SHOW_FAIL(selector, name) - (void)selector:(id)ad error:(NSError *)error { [self.events addObject:name]; }
EXT_METHOD(splashAd, @"splash.load")
EXT_METHOD(interstitialAd, @"interstitial.load")
EXT_METHOD(rewardedVideoAd, @"reward.load")
LOAD_FAIL(splashAd, @"splash.loadFail")
LOAD_FAIL(interstitialAd, @"interstitial.loadFail")
LOAD_FAIL(rewardedVideoAd, @"reward.loadFail")
SHOW_FAIL(splashAdDidShowFailed, @"splash.showFail")
SHOW_FAIL(interstitialAdDidShowFailed, @"interstitial.showFail")
SHOW_FAIL(rewardedVideoAdDidShowFailed, @"reward.showFail")
EVENT_METHOD(splashAdWillVisible, @"splash.visible")
EVENT_METHOD(splashAdDidClick, @"splash.click")
EVENT_METHOD(splashAdDidClose, @"splash.close")
EVENT_METHOD(interstitialAdRenderSuccess, @"interstitial.render")
EVENT_METHOD(interstitialAdDidVisible, @"interstitial.visible")
EVENT_METHOD(interstitialAdDidClick, @"interstitial.click")
EVENT_METHOD(interstitialAdDidClose, @"interstitial.close")
EVENT_METHOD(rewardedVideoAdVideoDidLoad, @"reward.videoLoad")
EVENT_METHOD(rewardedVideoAdDidVisible, @"reward.visible")
EVENT_METHOD(rewardedVideoAdDidClick, @"reward.click")
EVENT_METHOD(rewardedVideoAdDidClose, @"reward.close")
- (void)rewardedVideoAd:(id)ad didPlayFinishWithError:(NSError *)error { [self.events addObject:@"reward.playFinish"]; }
- (void)rewardedVideoAd:(id)ad didServerRewardSuccessWithInfo:(void (^)(BUMAdapterRewardAdInfo *))builder { builder([BUMAdapterRewardAdInfo new]); }
- (void)nativeAd:(id)ad didLoadWithExpressViews:(NSArray *)views exts:(NSArray *)exts { self.views = views; self.exts = exts; if (self.onNativeLoad) { self.onNativeLoad(); } }
- (void)nativeAd:(id)ad didLoadFailWithError:(NSError *)error { [self.events addObject:@"native.loadFail"]; }
- (void)nativeAd:(id)ad renderSuccessWithExpressView:(UIView *)view { [self.events addObject:@"native.render"]; }
- (void)nativeAd:(id)ad renderFailWithExpressView:(UIView *)view andError:(NSError *)error { [self.events addObject:@"native.renderFail"]; }
- (void)nativeAd:(id)ad didClickWithMediatedNativeAd:(id)view { [self.events addObject:@"native.click"]; }
- (void)nativeAd:(id)ad didVisibleWithMediatedNativeAd:(id)view { self.visibleView = view; [self.events addObject:@"native.visible"]; }
- (void)nativeAd:(id)ad didCloseWithExpressView:(UIView *)view closeReasons:(NSArray *)reasons { [self.events addObject:@"native.close"]; }
@end
