//
//  OSETCustomerGmNativeAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmNativeAdapter.h"
#import "OSETSDK/OSETSDK.h"


@interface OSETCustomerGmNativeAdapter()<OSETNativeAdDelegate>
@property (nonatomic,strong) OSETNativeAd *nativeAd;
@property (nonatomic, weak) UIViewController *viewController;

@end

@implementation OSETCustomerGmNativeAdapter

/// 当前加载的广告的状态，native模板广告
- (BUMMediatedAdStatus)mediatedAdStatusWithExpressView:(UIView *)view {
    return BUMMediatedAdStatusUnknown;
}

- (void)loadNativeAdWithSlotID:(nonnull NSString *)slotID andSize:(CGSize)size imageSize:(CGSize)imageSize parameter:(nonnull NSDictionary *)parameter {
    // 获取广告加载数量
    
    UIViewController * vc = [[UIViewController alloc]init];
    if(self.viewController){
        vc = self.viewController;
    }
    self.nativeAd = [[OSETNativeAd alloc] initWithSlotId:slotID size:size rootViewController:vc];
    self.nativeAd.delegate = self;
    [self.nativeAd loadAdData];

}

- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)nativeExpressViews{
    NSMutableArray *list = [[NSMutableArray alloc]init];
    NSMutableArray *exts = [[NSMutableArray alloc] init];
    for (int i = 0; i < nativeExpressViews.count; i++) {
        OSETBaseView * view = [nativeExpressViews objectAtIndex:i];
        [list addObject:view];
        [exts addObject:@{
            BUMMediaAdLoadingExtECPM : @(view.eCPM),
        }];
    }
    [self.bridge nativeAd:self didLoadWithExpressViews:[list copy] exts:exts.copy];
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
- (void)registerContainerView:(nonnull __kindof UIView *)containerView andClickableViews:(nonnull NSArray<__kindof UIView *> *)views forNativeAd:(nonnull id)nativeAd {

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
    // 在此处理Client Bidding的结果回调
//    NSLog(@"didReceiveBidResult = %@,%ld,%@,%@",result,(long)result.win,result.winnerPrice,result.winnerAdnID);

}

@end
