//
//  OSETCustomerGmRewardAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmRewardAdapter.h"
#import "OSETGmAdapterSupport.h"
@interface OSETCustomerGmRewardAdapter ()<OSETRewardVideoAdDelegate>
@property (nonatomic,strong) OSETRewardVideoAd *rewardVideoAd;
@property (nonatomic, assign) BOOL showing;

@property (nonatomic, weak) UIViewController *viewController;
@end
@implementation OSETCustomerGmRewardAdapter

- (BUMMediatedAdStatus)mediatedAdStatus {
    BUMMediatedAdStatus status = BUMMediatedAdStatusUnknown;
    status.valid = self.rewardVideoAd.isAdValid ? BUMMediatedAdStatusValueSure : BUMMediatedAdStatusValueDeny;
    return status;
}

- (void)loadRewardedVideoAdWithSlotID:(nonnull NSString *)slotID andParameter:(nonnull NSDictionary *)parameter {
    self.rewardVideoAd.delegate = nil;
    self.showing = NO;
    id value = parameter[BUMAdLoadingParamRVUserID] ?: parameter[@"user_id"];
    NSString *user_id = [value isKindOfClass:[NSString class]] ? value : @"";
    self.rewardVideoAd = [[OSETRewardVideoAd alloc] initWithSlotId:slotID withUserId:user_id];
    self.rewardVideoAd.delegate = self;
    [self.rewardVideoAd loadRewardAdData];
}

- (BOOL)showAdFromRootViewController:(UIViewController * _Nonnull)viewController parameter:(nonnull NSDictionary *)parameter {
    self.viewController = viewController;
    if(self.rewardVideoAd && self.rewardVideoAd.isAdValid && viewController){
        self.showing = YES;
        [self.rewardVideoAd showRewardFromRootViewController:viewController];
        return YES;
    }else{
        NSError * error = [[NSError alloc]initWithDomain:@"广告未加载成功或已失效" code:72000 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
        [self.bridge rewardedVideoAdDidShowFailed:self error:error];
        return NO;
    }
}

- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    OSETGmReportBidResult(self.rewardVideoAd, result);
}
- (void)rewardVideoDidReceiveSuccess:(nonnull id)rewardVideoAd slotId:(nonnull NSString *)slotId {
    [self.bridge rewardedVideoAd:self didLoadWithExt:OSETGmLoadingExt(self.rewardVideoAd.eCPM)];
    [self.bridge rewardedVideoAdVideoDidLoad:self];
}

- (void)rewardVideoLoadToFailed:(nonnull id)rewardVideoAd error:(nonnull NSError *)error {
    if (self.showing) {
        [self.bridge rewardedVideoAdDidShowFailed:self error:error];
    } else {
        [self.bridge rewardedVideoAd:self didLoadFailWithError:error ext:@{}];
    }
}

- (void)rewardVideoDidClick:(nonnull id)rewardVideoAd {
    [self.bridge rewardedVideoAdDidClick:self];
}

- (void)rewardVideoDidClose:(id)rewardVideoAd checkString:(NSString *)checkString{
    [self.bridge rewardedVideoAdDidClose:self];
}
//激励视频播放结束
- (void)rewardVideoPlayEnd:(id)rewardVideoAd  checkString:(NSString *)checkString{
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:nil];
}

//激励视频开始播放
- (void)rewardVideoPlayStart:(id)rewardVideoAd checkString:(NSString *)checkString{
    [self.bridge rewardedVideoAdDidVisible:self];
}
//激励视频奖励
- (void)rewardVideoOnReward:(id)rewardVideoAd checkString:(NSString *)checkString{
    [self.bridge rewardedVideoAd:self didServerRewardSuccessWithInfo:^(BUMAdapterRewardAdInfo * _Nonnull info) {
        info.rewardName = @"";
        info.rewardAmount = 0;
        info.tradeId = checkString;
        info.verify = YES;
    }];
}
-(void)rewardVideoRequestOnReward:(id)rewardVideoAd checkString:(NSString *)checkString withRequsetData:(NSDictionary *)requsetData{
    
}
//激励视频播放出错
- (void)rewardVideoPlayError:(id)rewardVideoAd error:(NSError *)error{
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:error];
}
- (void)didClick {
    
}

- (void)dealloc {
    _rewardVideoAd.delegate = nil;
}

@end
