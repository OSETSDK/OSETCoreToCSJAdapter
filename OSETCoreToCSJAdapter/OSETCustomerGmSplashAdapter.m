//
//  OSETCustomerGmSplashAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmSplashAdapter.h"
#import <OSETSDK/OSETSDK.h>
@interface OSETCustomerGmSplashAdapter ()<OSETSplashAdDelegate>

@property (nonatomic, strong) OSETSplashAd *splashAd;

@property (nonatomic, strong) UIView *customBottomView;

@end
@implementation OSETCustomerGmSplashAdapter


- (BUMMediatedAdStatus)mediatedAdStatus {
    BUMMediatedAdStatus status = BUMMediatedAdStatusUnknown;
    status.valid = self.splashAd.isAdValid ? BUMMediatedAdStatusValueSure : BUMMediatedAdStatusValueDeny;
    return status;
}

- (void)dismissSplashAd {
//    [self.splashView removeFromSuperview];
    [self.customBottomView removeFromSuperview];
}

- (void)loadSplashAdWithSlotID:(nonnull NSString *)slotID andParameter:(nonnull NSDictionary *)parameter {

    self.customBottomView = parameter[BUMAdLoadingParamSPCustomBottomView];

    UIWindow * window;
    if(self.bridge.viewControllerForPresentingModalView.view.window){
        window = self.bridge.viewControllerForPresentingModalView.view.window;
    }
    if(!window){
        window  = [UIApplication sharedApplication].keyWindow;
    }
    self.splashAd = [[OSETSplashAd alloc] initWithSlotId:slotID window:window bottomView:self.customBottomView];
    self.splashAd.delegate = self;
    [self.splashAd loadSplashAd];
}

- (void)showSplashAdInWindow:(nonnull UIWindow *)window parameter:(nonnull NSDictionary *)parameter {
    
    if(self.splashAd  && self.splashAd.isAdValid){
        [self.splashAd showSplashAd];
        [self.bridge splashAdWillVisible:self];
    }else{
        NSError * error = [[NSError alloc]initWithDomain:@"广告未加载成功或已失效" code:72000 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
        [self.bridge splashAdDidShowFailed:self error:error];
    }
}
#pragma mark OSETSplashAdDelegate
- (void)splashDidReceiveSuccess:(nonnull id)splashAd slotId:(nonnull NSString *)slotId {
    // 加载广告成功
    NSLog(@"splashDidReceiveSuccess ecpm =  %@",@(MAX(self.splashAd.eCPM, 0)));
    [self.bridge splashAd:self didLoadWithExt:@{BUMMediaAdLoadingExtECPM:@(MAX(self.splashAd.eCPM, 0))}];
}
- (void)splashLoadToFailed:(nonnull id)splashAd error:(nonnull NSError *)error {
    NSLog(@"oset加载失败%@",error);
    [self.bridge splashAd:self didLoadFailWithError:error ext:@{}];
}

- (void)splashDidClick:(nonnull id)splashAd {
    [self.bridge splashAdDidClick:self];
}
/// 开屏将要关闭
- (void)splashWillClose:(id)splashAd{
    NSLog(@"oset开屏将要关闭");
}
- (void)splashDidClose:(nonnull id)splashAd {
    [self.bridge splashAdDidClose:self];
}
- (void)splashAdExposured:(id)splashAd{
    [self.bridge splashAdWillVisible:self];
}
- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    // 在此处理Client Bidding的结果回调
    if (result.win) {
    } else {
    }
}
@end
