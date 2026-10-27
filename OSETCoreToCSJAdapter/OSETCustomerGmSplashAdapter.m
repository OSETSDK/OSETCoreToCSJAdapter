//
//  OSETCustomerGmSplashAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmSplashAdapter.h"
#import "OSETGmAdapterSupport.h"
@interface OSETCustomerGmSplashAdapter ()<OSETSplashAdDelegate>

@property (nonatomic, strong) OSETSplashAd *splashAd;

@property (nonatomic, strong) UIView *customBottomView;
@property (nonatomic, assign) BOOL dismissed;
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL finished;

@end
@implementation OSETCustomerGmSplashAdapter


- (BUMMediatedAdStatus)mediatedAdStatus {
    BUMMediatedAdStatus status = BUMMediatedAdStatusUnknown;
    status.valid = self.splashAd.isAdValid ? BUMMediatedAdStatusValueSure : BUMMediatedAdStatusValueDeny;
    return status;
}

- (void)dismissSplashAd {
    self.dismissed = YES;
    self.showing = NO;
    OSETSplashAd *ad = self.splashAd;
    UIView *bottomView = self.customBottomView;
    self.splashAd = nil;
    self.customBottomView = nil;
    OSETGmDismissSplash(ad, bottomView);
}

- (void)loadSplashAdWithSlotID:(nonnull NSString *)slotID andParameter:(nonnull NSDictionary *)parameter {

    [self dismissSplashAd];
    self.dismissed = NO;
    self.visible = NO;
    self.finished = NO;
    id bottomView = parameter[BUMAdLoadingParamSPCustomBottomView];
    self.customBottomView = [bottomView isKindOfClass:[UIView class]] ? bottomView : nil;

    UIWindow *window = nil;
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
    
    if (!self.dismissed && !self.finished && self.splashAd.isAdValid && window) {
        if (self.showing) {
            return;
        }
        self.showing = YES;
        // 使用展示时的窗口，不继续沿用加载阶段的 keyWindow。
        [self.splashAd showSplashAdWithWindow:window bottomView:self.customBottomView];
    }else{
        NSError * error = [[NSError alloc]initWithDomain:@"广告未加载成功或已失效" code:72000 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
        [self.bridge splashAdDidShowFailed:self error:error];
    }
}
#pragma mark OSETSplashAdDelegate
- (void)splashDidReceiveSuccess:(nonnull id)splashAd slotId:(nonnull NSString *)slotId {
    if (self.dismissed || self.finished) { return; }
    // 加载广告成功
    NSInteger price = self.splashAd.eCPM;
    [self.bridge splashAd:self didLoadWithExt:OSETGmLoadingExt(price)];
}
- (void)splashLoadToFailed:(nonnull id)splashAd error:(nonnull NSError *)error {
    if (self.dismissed || self.finished) { return; }
    self.finished = YES;
    if (self.showing) {
        [self.bridge splashAdDidShowFailed:self error:error];
    } else {
        [self.bridge splashAd:self didLoadFailWithError:error ext:@{}];
    }
}

- (void)splashDidClick:(nonnull id)splashAd {
    if (self.dismissed || self.finished) { return; }
    [self.bridge splashAdDidClick:self];
}
/// 开屏将要关闭
- (void)splashWillClose:(id)splashAd{
}
- (void)splashDidClose:(nonnull id)splashAd {
    if (self.dismissed || self.finished) { return; }
    self.finished = YES;
    [self.bridge splashAdDidClose:self];
}
- (void)splashAdExposured:(id)splashAd{
    if (self.dismissed || self.finished || !self.showing || self.visible) { return; }
    self.visible = YES;
    [self.bridge splashAdWillVisible:self];
}
- (void)splashAdExposuredToFailed:(id)splashAd error:(NSError *)error {
    if (self.dismissed || self.finished) { return; }
    self.finished = YES;
    [self.bridge splashAdDidShowFailed:self error:error];
}
- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    OSETGmReportBidResult(self.splashAd, result);
}
- (void)dealloc {
    OSETGmDismissSplash(_splashAd, _customBottomView);
}
@end
