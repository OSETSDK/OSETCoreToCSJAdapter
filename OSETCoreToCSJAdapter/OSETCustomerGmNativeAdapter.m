#import "OSETCustomerGmNativeAdapter.h"
#import "OSETGmAdapterSupport.h"
#import "OSETCustomerGmNativeAdData.h"
#import "OSETCustomerGmNativeAdViewCreator.h"

@interface OSETCustomerGmNativeAdapter () <OSETNativeAdDelegate, OSETNativeDataAdDelegate, OSETNativeAdRendererDelegate>
@property (nonatomic, strong) OSETNativeAd *nativeAd;
@property (nonatomic, strong) OSETNativeDataAd *nativeDataAd;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NSArray<OSETBaseView *> *expressViews;
@property (nonatomic, copy) NSArray<OSETCustomerGmNativeAdViewCreator *> *nativeCreators;
@property (nonatomic, assign) BOOL selfRendering;
@property (nonatomic, assign) BOOL loadFinished;
@end

@implementation OSETCustomerGmNativeAdapter

- (void)clearAds {
    self.nativeAd.delegate = nil;
    self.nativeDataAd.delegate = nil;
    NSArray *creators = self.nativeCreators;
    self.nativeCreators = @[];
    self.expressViews = @[];
    self.nativeAd = nil;
    self.nativeDataAd = nil;
    for (OSETCustomerGmNativeAdViewCreator *creator in creators) { [creator invalidate]; }
}

// Factories keep the real loading path testable without changing production behavior.
- (OSETNativeDataAd *)newNativeDataAdWithSlotID:(NSString *)slotID size:(CGSize)size viewController:(UIViewController *)vc {
    return [[OSETNativeDataAd alloc] initWithSlotId:slotID size:size rootViewController:vc];
}
- (OSETNativeAdRenderer *)newNativeRenderer { return [OSETNativeAdRenderer new]; }
- (OSETNativeAd *)newNativeAdWithSlotID:(NSString *)slotID size:(CGSize)size viewController:(UIViewController *)vc {
    return [[OSETNativeAd alloc] initWithSlotId:slotID size:size rootViewController:vc];
}

- (void)loadNativeAdWithSlotID:(NSString *)slotID andSize:(CGSize)size imageSize:(CGSize)imageSize parameter:(NSDictionary *)parameter {
    [self clearAds];
    self.loadFinished = NO;
    id value = parameter[BUMAdLoadingParamExpressAdType];
    NSInteger renderType = 0;
    if (value) {
        BOOL number = [value isKindOfClass:NSNumber.class];
        BOOL string = [value isKindOfClass:NSString.class] && [@[@"0", @"1", @"2"] containsObject:value];
        if (!number && !string) { [self failLoad:[self adapterError:@"无效的信息流渲染类型"]]; return; }
        if (number && ![@[@0, @1, @2] containsObject:value]) { [self failLoad:[self adapterError:@"未知的信息流渲染类型"]]; return; }
        renderType = [value integerValue];
    }
    // Preserve existing template behavior when GroMore does not distinguish render types.
    self.selfRendering = renderType == 2;
#if DEBUG
    NSLog(@"[OSETGMNative] request renderType=%ld selfRendering=%d", (long)renderType, self.selfRendering);
#endif
    UIViewController *vc = self.viewController ?: self.bridge.viewControllerForPresentingModalView;
    id mute = parameter[BUMAdLoadingParamNAIsMute];
    BOOL muted = [mute isKindOfClass:NSNumber.class] ? [mute boolValue] : YES;
    if (self.selfRendering) {
        self.nativeDataAd = [self newNativeDataAdWithSlotID:slotID size:size viewController:vc];
        self.nativeDataAd.delegate = self;
        self.nativeDataAd.videoMuted = muted;
        [self.nativeDataAd loadAdData];
    } else {
        self.nativeAd = [self newNativeAdWithSlotID:slotID size:size viewController:vc];
        self.nativeAd.delegate = self;
        self.nativeAd.videoMuted = muted;
        [self.nativeAd loadAdData];
    }
}

- (NSError *)adapterError:(NSString *)message {
    return [NSError errorWithDomain:@"OSETGroMoreNativeAdapter" code:72002 userInfo:@{NSLocalizedDescriptionKey: message}];
}
- (void)failLoad:(NSError *)error {
    if (self.loadFinished) { return; }
    self.loadFinished = YES;
    [self.bridge nativeAd:self didLoadFailWithError:error];
}

- (void)nativeDataAdLoadSuccessWithNative:(id)nativeDataAd nativeDataObjects:(NSArray<OSETNativeDataAdObject *> *)objects {
    OSETNativeDataAd *loadedAd = self.nativeDataAd;
    if (!self.selfRendering || nativeDataAd != loadedAd || !loadedAd || self.loadFinished) { return; }
    OSETNativeDataAdObject *data = [objects isKindOfClass:NSArray.class] ? objects.firstObject : nil;
    if (![data isKindOfClass:OSETNativeDataAdObject.class] || !data.isAdValid) {
        [self failLoad:[self adapterError:@"自渲染广告返回空素材或素材已失效"]]; return;
    }
    OSETCustomerGmNativeAdData *material = [[OSETCustomerGmNativeAdData alloc] initWithDataObject:data];
    if (!data.isVideoAd && material.imageList.count == 0) {
        [self failLoad:[self adapterError:@"图文广告没有可用的图片素材"]]; return;
    }
    OSETNativeAdRenderer *renderer = [self newNativeRenderer];
    OSETCustomerGmNativeAdViewCreator *creator = [[OSETCustomerGmNativeAdViewCreator alloc] initWithDataObject:data loadedAd:loadedAd renderer:renderer];
    if (data.isVideoAd && ![renderer.mediaView isKindOfClass:UIView.class]) {
        [creator invalidate];
        [self failLoad:[self adapterError:@"视频广告未提供可用的媒体视图"]]; return;
    }
    renderer.delegate = self;
    creator.viewController = self.viewController ?: self.bridge.viewControllerForPresentingModalView;
    BUMMediatedNativeAd *ad = [BUMMediatedNativeAd new];
    ad.data = material;
    ad.viewCreator = creator;
    ad.view = [UIView new];
    ad.originMediatedNativeAd = data;
    // Save ownership before the bridge can synchronously return bid/registration callbacks.
    self.nativeCreators = @[creator];
    self.loadFinished = YES;
#if DEBUG
    NSLog(@"[OSETGMNative] loaded native material video=%d ecpm=%ld", data.isVideoAd, (long)data.eCPM);
#endif
    [self.bridge nativeAd:self didLoadWithNativeAds:@[ad] exts:@[OSETGmLoadingExt(data.eCPM)]];
}
- (void)nativeDataAdFailedToLoad:(id)nativeDataAd error:(NSError *)error {
    if (self.selfRendering && nativeDataAd == self.nativeDataAd) { [self failLoad:error]; }
}

- (OSETCustomerGmNativeAdViewCreator *)creatorForOrigin:(id)origin {
    for (OSETCustomerGmNativeAdViewCreator *creator in self.nativeCreators) {
        if (creator.dataObject == origin) { return creator; }
    }
    return nil;
}
- (OSETCustomerGmNativeAdViewCreator *)creatorForRenderer:(OSETNativeAdRenderer *)renderer {
    for (OSETCustomerGmNativeAdViewCreator *creator in self.nativeCreators) {
        if (creator.renderer == renderer) { return creator; }
    }
    return nil;
}

- (void)registerContainerView:(UIView *)containerView andClickableViews:(NSArray<UIView *> *)views forNativeAd:(id)nativeAd {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForOrigin:nativeAd];
    if (!creator || creator.invalidated) { return; }
    creator.viewController = creator.viewController ?: self.bridge.viewControllerForPresentingModalView;
    [creator registerContainer:containerView clickableViews:views];
}
- (void)unregisterClickableViewsForNativeAd:(id)nativeAd {
    [[self creatorForOrigin:nativeAd] unregisterViews];
}
- (void)setRootViewController:(UIViewController *)viewController forNativeAd:(id)nativeAd {
    [self creatorForOrigin:nativeAd].viewController = viewController;
}
- (BUMMediatedAdStatus)mediatedAdStatusWithMediatedNativeAd:(BUMMediatedNativeAd *)ad {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForOrigin:ad.originMediatedNativeAd];
    BUMMediatedAdStatus status = BUMMediatedAdStatusUnknown;
    status.valid = creator && !creator.invalidated && creator.dataObject.isAdValid ? BUMMediatedAdStatusValueSure : BUMMediatedAdStatusValueDeny;
    return status;
}

- (void)OSETNativeAdRendererWillExpose:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (creator && !creator.invalidated && creator.registered) { [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:creator.dataObject]; }
}
- (void)OSETNativeAdRendererDidClick:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (creator && !creator.invalidated && creator.registered) { [self.bridge nativeAd:self didClickWithMediatedNativeAd:creator.dataObject]; }
}
- (void)OSETNativeAdRendererDidClose:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (!creator || creator.invalidated || !creator.registered) { return; }
    OSETNativeDataAdObject *origin = creator.dataObject;
    [creator invalidate];
    [self.bridge nativeAd:self dislikeWithMediatedNativeAd:origin closeReasons:@[]];
}
- (void)OSETNativeAdRendererDetailViewClosed:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (creator && !creator.invalidated && creator.registered) { [self.bridge nativeAd:self didDismissFullScreenModalWithMediatedNativeAd:creator.dataObject]; }
}
- (void)OSETNativeAdRendererPlayStart:(OSETNativeAdRenderer *)renderer {
    [self reportVideoState:BUPlayerStatePlaying renderer:renderer];
}
- (void)OSETNativeAdRendererPlayError:(OSETNativeAdRenderer *)renderer error:(NSError *)error {
    [self reportVideoState:BUPlayerStateFailed renderer:renderer];
}
- (void)OSETNativeAdRendererPlayComplete:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (creator && !creator.invalidated && creator.registered) {
        [self.bridge nativeAd:self videoDidPlayFinish:creator.dataObject];
    }
}
- (void)reportVideoState:(BUPlayerPlayState)state renderer:(OSETNativeAdRenderer *)renderer {
    OSETCustomerGmNativeAdViewCreator *creator = [self creatorForRenderer:renderer];
    if (creator && !creator.invalidated && creator.registered) {
        [self.bridge nativeAd:self videoStateDidChangedWithState:state andNativeAd:creator.dataObject];
    }
}

#pragma mark - Existing template path
- (BUMMediatedAdStatus)mediatedAdStatusWithExpressView:(UIView *)view { return BUMMediatedAdStatusUnknown; }
- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)values {
    if (self.selfRendering || native != self.nativeAd || self.loadFinished) { return; }
    NSMutableArray *views = [NSMutableArray array], *exts = [NSMutableArray array];
    for (id view in ([values isKindOfClass:NSArray.class] ? values : @[])) {
        if (![view isKindOfClass:OSETBaseView.class]) { continue; }
        [views addObject:view]; [exts addObject:OSETGmLoadingExt([(OSETBaseView *)view eCPM])];
    }
    if (!views.count) { [self failLoad:[self adapterError:@"模板信息流返回空广告"]]; return; }
    self.expressViews = views.copy;
    self.loadFinished = YES;
    [self.bridge nativeAd:self didLoadWithExpressViews:self.expressViews exts:exts.copy];
}
- (void)nativeExpressAdFailedToLoad:(id)ad error:(NSError *)error {
    if (!self.selfRendering && ad == self.nativeAd) { [self failLoad:error]; }
}
- (void)nativeExpressAdRenderSuccess:(id)view {}
- (void)nativeExpressAdFailedToRender:(id)view {
    [self.bridge nativeAd:self renderFailWithExpressView:view andError:[self adapterError:@"信息流渲染失败"]];
}
- (void)nativeExpressAdDidClick:(id)view { [self.bridge nativeAd:self didClickWithMediatedNativeAd:view]; }
- (void)nativeExpressAdDidClose:(id)view { [self.bridge nativeAd:self didCloseWithExpressView:view closeReasons:@[]]; }
- (void)nativeExpressAdDidExposured:(id)value {
    NSArray *views = self.expressViews;
    if (!views.count || ![value isKindOfClass:UIView.class]) { return; }
    for (UIView *view = value; view; view = view.superview) {
        NSUInteger index = [views indexOfObjectIdenticalTo:view];
        if (index != NSNotFound) { [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:views[index]]; return; }
    }
}
- (void)renderForExpressAdView:(UIView *)view { [self.bridge nativeAd:self renderSuccessWithExpressView:view]; }
- (void)setRootViewController:(UIViewController *)vc forExpressAdView:(UIView *)view {
    self.viewController = vc; self.nativeAd.viewController = vc;
}
- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    if (self.selfRendering) {
        NSMutableArray *origins = [NSMutableArray array];
        for (OSETCustomerGmNativeAdViewCreator *creator in self.nativeCreators) { [origins addObject:creator.dataObject]; }
        OSETGmReportNativeDataBidResult(self.nativeDataAd, origins.copy, result);
    } else {
        OSETGmReportNativeBidResult(self.expressViews, result);
    }
}
- (void)dealloc {
    _nativeAd.delegate = nil; _nativeDataAd.delegate = nil;
    NSArray *creators = _nativeCreators;
    if (NSThread.isMainThread) {
        for (OSETCustomerGmNativeAdViewCreator *creator in creators) { [creator invalidate]; }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (OSETCustomerGmNativeAdViewCreator *creator in creators) { [creator invalidate]; }
        });
    }
}
@end
