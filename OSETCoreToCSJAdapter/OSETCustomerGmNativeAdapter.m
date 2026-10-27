//
//  OSETCustomerGmNativeAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmNativeAdapter.h"
#import "OSETGmAdapterSupport.h"


@interface OSETCustomerGmNativeAdapter()<OSETNativeAdDelegate>
@property (nonatomic,strong) OSETNativeAd *nativeAd;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NSArray<OSETBaseView *> *expressViews;

@end

@implementation OSETCustomerGmNativeAdapter

/// 当前加载的广告的状态，native模板广告
- (BUMMediatedAdStatus)mediatedAdStatusWithExpressView:(UIView *)view {
    return BUMMediatedAdStatusUnknown;
}

- (void)loadNativeAdWithSlotID:(nonnull NSString *)slotID andSize:(CGSize)size imageSize:(CGSize)imageSize parameter:(nonnull NSDictionary *)parameter {
    self.nativeAd.delegate = nil;
    self.expressViews = @[];
    UIViewController *vc = self.viewController ?: self.bridge.viewControllerForPresentingModalView;
    self.nativeAd = [[OSETNativeAd alloc] initWithSlotId:slotID size:size rootViewController:vc];
    self.nativeAd.delegate = self;
    [self.nativeAd loadAdData];

}

- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)nativeExpressViews{
    NSMutableArray<OSETBaseView *> *list = [[NSMutableArray alloc]init];
    NSMutableArray *exts = [[NSMutableArray alloc] init];
    for (int i = 0; i < nativeExpressViews.count; i++) {
        id view = [nativeExpressViews objectAtIndex:i];
        if (![view isKindOfClass:[OSETBaseView class]]) { continue; }
        [list addObject:view];
        [exts addObject:OSETGmLoadingExt([(OSETBaseView *)view eCPM])];
    }
    // bridge 的加载回调可能同步触发比价结果，必须先保存广告归属。
    self.expressViews = list.copy;
    [self.bridge nativeAd:self didLoadWithExpressViews:self.expressViews exts:exts.copy];
}
- (void)nativeExpressAdRenderSuccess:(id)nativeExpressView{
//    [self.bridge nativeAd:self renderSuccessWithExpressView:nativeExpressView];
}
- (void)nativeExpressAdFailedToLoad:(nonnull id)nativeExpressAd error:(nonnull NSError *)error {
    [self.bridge nativeAd:self didLoadFailWithError:error];
}
- (void)nativeExpressAdFailedToRender:(nonnull id)nativeExpressView {
    NSError * error = [[NSError alloc]initWithDomain:@"nativeExpressAdFailedToRender" code:72001 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
    [self.bridge nativeAd:self renderFailWithExpressView:nativeExpressView andError:error];
}
- (void)nativeExpressAdDidClick:(nonnull id)nativeExpressView {
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:nativeExpressView];
}
- (void)nativeExpressAdDidClose:(nonnull id)nativeExpressView {
    [self.bridge nativeAd:self didCloseWithExpressView:nativeExpressView closeReasons:@[]];


}
- (void)nativeExpressAdDidExposured:(id)nativeExpressView {
    // 必须回传加载时交给 GroMore 的同一个模板 View。
    NSArray<OSETBaseView *> *views = self.expressViews;
    if (!views.count || ![nativeExpressView isKindOfClass:[UIView class]]) { return; }
    UIView *view = nativeExpressView;
    while (view) {
        NSUInteger index = [(NSArray *)views indexOfObjectIdenticalTo:view];
        if (index != NSNotFound) {
            [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:views[index]];
            return;
        }
        view = view.superview;
    }
}
- (void)registerContainerView:(nonnull __kindof UIView *)containerView andClickableViews:(nonnull NSArray<__kindof UIView *> *)views forNativeAd:(nonnull id)nativeAd {

}
- (void)unregisterClickableViewsForNativeAd:(id)nativeAd {
    // 当前适配器仅返回 OSET 模板广告，点击区域由 OSET 管理，无额外注册需要撤销。
}

- (void)renderForExpressAdView:(nonnull UIView *)expressAdView {
    // 如不adn广告不需要render，请尽量模拟回调renderSuccess
    [self.bridge nativeAd:self renderSuccessWithExpressView:expressAdView];
}

- (void)setRootViewController:(nonnull UIViewController *)viewController forExpressAdView:(nonnull UIView *)expressAdView {
    self.viewController = viewController;
    self.nativeAd.viewController = viewController;
}

- (void)setRootViewController:(nonnull UIViewController *)viewController forNativeAd:(nonnull id)nativeAd { 
    self.viewController = viewController;
    self.nativeAd.viewController = viewController;
}
- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    OSETGmReportNativeBidResult(self.expressViews, result);
}
- (void)dealloc {
    _nativeAd.delegate = nil;
}

@end
