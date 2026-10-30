#ifndef OSETGmAdapterSupport_h
#define OSETGmAdapterSupport_h

#import <BUAdSDK/BUAdSDK.h>
#import <OSETSDK/OSETSDK.h>
#import <dispatch/dispatch.h>

// 协议只声明可选能力，不要求旧版 OSETSDK 导出新的方法或字段常量。
@protocol OSETGmBiddingReporting <NSObject>
- (void)reportBiddingWinWithInfo:(NSDictionary *)info;
- (void)reportBiddingLossWithInfo:(NSDictionary *)info;
@end

@protocol OSETGmSplashDismissing <NSObject>
- (void)interceptSplashadView;
@end

static inline NSDictionary *OSETGmLoadingExt(NSInteger price) {
    // -1 表示价格不可用，不把它伪造成有效的竞价价格。
    return price < 0 ? @{} : @{BUMMediaAdLoadingExtECPM : [NSString stringWithFormat:@"%ld", (long)price]};
}

// 每次有效竞价通知都转交 OSETSDK，去重由 SDK 负责。
static inline void OSETGmReportBidResult(id ad, BUMMediaBidResult *result) {
    @try {
        if (![result isKindOfClass:[BUMMediaBidResult class]] ||
            ![result respondsToSelector:@selector(win)] ||
            (![ad isKindOfClass:[OSETBaseAd class]] && ![ad isKindOfClass:[OSETBaseView class]])) {
            return;
        }
        if (![NSThread isMainThread]) {
            // 固定回调时的广告对象，不能在异步执行时改读下一次加载的广告。
            dispatch_async(dispatch_get_main_queue(), ^{ OSETGmReportBidResult(ad, result); });
            return;
        }
        BOOL win = result.win;
        SEL selector = win ? @selector(reportBiddingWinWithInfo:) : @selector(reportBiddingLossWithInfo:);
        if (![ad respondsToSelector:selector]) {
            return;
        }
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        // 与 OSETBaseAd 的公开字段值一致；使用字面量兼容尚未导出常量的旧 SDK。
        info[@"biddingExtra"] = @{@"mediation" : @"GroMore", @"win" : @(win)};
        if (win && [result respondsToSelector:@selector(winnerPrice)]) {
            NSInteger price = result.winnerPrice;
            if (price > 0) {
                info[@"biddingPrice"] = @(price);
            }
        }
        // GroMore 仅提供失败描述，没有可直接映射的失败原因枚举，交由 SDK 使用默认原因。
        if (win) {
            [(id<OSETGmBiddingReporting>)ad reportBiddingWinWithInfo:info.copy];
        } else {
            [(id<OSETGmBiddingReporting>)ad reportBiddingLossWithInfo:info.copy];
        }
    } @catch (NSException *exception) {
        // 上报异常不得影响广告主流程，也不在异常路径格式化外部对象。
        (void)exception;
    }
}

static inline void OSETGmReportNativeBidResult(NSArray<OSETBaseView *> *views, BUMMediaBidResult *result) {
    @try {
        if (![result isKindOfClass:[BUMMediaBidResult class]] || ![views isKindOfClass:[NSArray class]] || !views.count) {
            return;
        }
        if (![NSThread isMainThread]) {
            NSArray *snapshot = views.copy;
            dispatch_async(dispatch_get_main_queue(), ^{ OSETGmReportNativeBidResult(snapshot, result); });
            return;
        }
        id origin = [result respondsToSelector:@selector(originNativeAdData)] ? result.originNativeAdData : nil;
        if (origin) {
            NSUInteger index = [views indexOfObjectIdenticalTo:origin];
            if (index != NSNotFound) {
                OSETGmReportBidResult(views[index], result);
            }
        } else if (views.count == 1) {
            // 缺少归属信息时仅允许单广告回退，不能把多条广告的结果上报给任意一条。
            OSETGmReportBidResult(views.firstObject, result);
        }
    } @catch (NSException *exception) {
        (void)exception;
    }
}

static inline void OSETGmReportNativeDataBidResult(OSETNativeDataAd *ad, NSArray *origins, BUMMediaBidResult *result) {
    @try {
        if (![result isKindOfClass:BUMMediaBidResult.class] || !origins.count || !ad) { return; }
        if (!NSThread.isMainThread) {
            dispatch_async(dispatch_get_main_queue(), ^{ OSETGmReportNativeDataBidResult(ad, origins, result); });
            return;
        }
        id origin = [result respondsToSelector:@selector(originNativeAdData)] ? result.originNativeAdData : nil;
        if ((origin && [origins indexOfObjectIdenticalTo:origin] != NSNotFound) || (!origin && origins.count == 1)) {
            OSETGmReportBidResult(ad, result);
        }
    } @catch (NSException *exception) {
        (void)exception;
    }
}

static inline void OSETGmDismissSplash(OSETSplashAd *ad, UIView *bottomView) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ OSETGmDismissSplash(ad, bottomView); });
        return;
    }
    ad.delegate = nil;
    @try {
        // 既有 SDK 的拦截入口未放在公开头文件中；必须先检查能力。
        // 该入口负责阻止尚未执行的 show，具体渠道视图的清理由 SDK 实现负责。
        if ([ad respondsToSelector:@selector(interceptSplashadView)]) {
            [(id<OSETGmSplashDismissing>)ad interceptSplashadView];
        }
    } @catch (NSException *exception) {
        (void)exception;
    }
    [bottomView removeFromSuperview];
}

#endif
