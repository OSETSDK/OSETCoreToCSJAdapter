//
//  OSETCustomerGmRewardAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmRewardAdapter.h"
#import <OSETSDK/OSETSDK.h>
@interface OSETCustomerGmRewardAdapter ()<OSETRewardVideoAdDelegate>
@property (nonatomic,strong) OSETRewardVideoAd *rewardVideoAd;

@property (nonatomic, weak) UIViewController *viewController;
@end
@implementation OSETCustomerGmRewardAdapter

- (BUMMediatedAdStatus)mediatedAdStatus {
    return BUMMediatedAdStatusNormal;
}

- (void)loadRewardedVideoAdWithSlotID:(nonnull NSString *)slotID andParameter:(nonnull NSDictionary *)parameter {
    NSString * user_id = @"";
    if(parameter[@"user_id"]){
        user_id = parameter[@"user_id"];
    }
    self.rewardVideoAd = [[OSETRewardVideoAd alloc] initWithSlotId:slotID withUserId:user_id];
    self.rewardVideoAd.delegate = self;
    [self.rewardVideoAd loadRewardAdData];
}

- (BOOL)showAdFromRootViewController:(UIViewController * _Nonnull)viewController parameter:(nonnull NSDictionary *)parameter {
    self.viewController = viewController;
    if(self.rewardVideoAd && self.rewardVideoAd.isAdValid && viewController){
        [self.rewardVideoAd showRewardFromRootViewController:self.viewController];
        return YES;
    }else{
        NSError * error = [[NSError alloc]initWithDomain:@"广告未加载成功或已失效" code:72000 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"OSETBU"]}];
        [self.bridge rewardedVideoAd:self didLoadFailWithError:error ext:@{}];
        return NO;
    }
}

- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    // 在此处理Client Bidding的结果回调
    NSLog(@"didReceiveBidResult = %@,%ld,%@,%@",result,(long)result.win,result.winnerPrice,result.winnerAdnID);
}
- (void)rewardVideoDidReceiveSuccess:(nonnull id)rewardVideoAd slotId:(nonnull NSString *)slotId {
    [self.bridge rewardedVideoAd:self didLoadWithExt:@{BUMMediaAdLoadingExtECPM:@(MAX(self.rewardVideoAd.eCPM, 0))}];
    [self.bridge rewardedVideoAdVideoDidLoad:self];
}

- (void)rewardVideoLoadToFailed:(nonnull id)rewardVideoAd error:(nonnull NSError *)error {
    [self.bridge rewardedVideoAd:self didLoadFailWithError:error ext:@{}];
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


@end
