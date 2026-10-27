//
//  OSETCustomerGmInterstitialAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmInterstitialAdapter.h"
#import "OSETGmAdapterSupport.h"

@interface OSETCustomerGmInterstitialAdapter ()<OSETInterstitialAdDelegate>

@property (nonatomic, strong) OSETInterstitialAd *interstitialAd;

@property (nonatomic, weak) UIViewController *viewController;

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL showing;

@end

@implementation OSETCustomerGmInterstitialAdapter

- (BUMMediatedAdStatus)mediatedAdStatus {
    BUMMediatedAdStatus status = BUMMediatedAdStatusUnknown;
    status.valid = self.interstitialAd.isAdValid ? BUMMediatedAdStatusValueSure : BUMMediatedAdStatusValueDeny;
    return status;

}

- (void)loadInterstitialAdWithSlotID:(NSString *)slotID andSize:(CGSize)size parameter:(NSDictionary *)parameter {
    self.interstitialAd.delegate = nil;
    self.showing = NO;
    self.size = size;
    self.interstitialAd = [[OSETInterstitialAd alloc] initWithSlotId:slotID];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadInterstitialAdData];
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController parameter:(NSDictionary *)parameter {
    self.viewController = viewController;
    if(self.interstitialAd  && self.interstitialAd.isAdValid && viewController){
        self.showing = YES;
        [self.interstitialAd showInterstitialFromRootViewController:viewController];
        return YES;
    }else{
        NSError * error = [[NSError alloc]initWithDomain:@"广告未加载成功或已失效" code:72000 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
        [self.bridge interstitialAdDidShowFailed:self error:error];
        return NO;
    }
}

- (void)interstitialDidReceiveSuccess:(nonnull id)interstitialAd slotId:(nonnull NSString *)slotId {
    [self.bridge interstitialAd:self didLoadWithExt:OSETGmLoadingExt(self.interstitialAd.eCPM)];
    [self.bridge interstitialAdRenderSuccess:self];
}

- (void)interstitialLoadToFailed:(nonnull id)interstitialAd error:(nonnull NSError *)error {
    if (self.showing) {
        [self.bridge interstitialAdDidShowFailed:self error:error];
    } else {
        [self.bridge interstitialAd:self didLoadFailWithError:error ext:@{}];
    }
}

- (void)interstitialDidClick:(nonnull id)interstitialAd {
    [self.bridge interstitialAdDidClick:self];
}
-(void)interstitialExposured:(id)interstitialAd{
    [self.bridge interstitialAdDidVisible:self];
}
- (void)interstitialDidClose:(nonnull id)interstitialAd {
    [self.bridge interstitialAdDidClose:self];
}
- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    OSETGmReportBidResult(self.interstitialAd, result);
}

- (void)dealloc {
    _interstitialAd.delegate = nil;
}

@end
