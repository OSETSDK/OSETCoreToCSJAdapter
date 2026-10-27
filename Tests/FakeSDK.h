// Controlled doubles for adapter behavior tests. They do not simulate ad delivery.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <dispatch/dispatch.h>

@class UIWindow;
@interface UIView : NSObject
@property (nonatomic, weak) UIView *superview;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic) BOOL removed;
- (void)removeFromSuperview;
@end
@interface UIViewController : NSObject
@property (nonatomic, strong) UIView *view;
@end
@interface UIWindow : UIView
@end
@interface UIApplication : NSObject
@property (nonatomic, strong) UIWindow *keyWindow;
+ (instancetype)sharedApplication;
@end

typedef NS_ENUM(NSInteger, BUMMediatedAdStatusValue) {
    BUMMediatedAdStatusValueUnknown, BUMMediatedAdStatusValueSure, BUMMediatedAdStatusValueDeny
};
typedef struct { BUMMediatedAdStatusValue isReady, unexpired, valid; } BUMMediatedAdStatus;
extern const BUMMediatedAdStatus BUMMediatedAdStatusUnknown;
extern NSString *const BUMMediaAdLoadingExtECPM;
extern NSString *const BUMAdLoadingParamSPCustomBottomView;
extern NSString *const BUMAdLoadingParamRVUserID;
@interface BUMMediaBidResult : NSObject
@property BOOL win;
@property NSInteger winnerPrice;
@property (nonatomic, strong) id originNativeAdData;
@end
@interface BUMAdapterRewardAdInfo : NSObject
@property (nonatomic, copy) NSString *rewardName;
@property NSInteger rewardAmount;
@property (nonatomic, copy) NSString *tradeId;
@property BOOL verify;
@end
@protocol GMTestBridge <NSObject>
- (UIViewController *)viewControllerForPresentingModalView;
- (void)splashAd:(id)ad didLoadWithExt:(NSDictionary *)ext;
- (void)splashAd:(id)ad didLoadFailWithError:(NSError *)error ext:(NSDictionary *)ext;
- (void)splashAdDidShowFailed:(id)ad error:(NSError *)error;
- (void)splashAdWillVisible:(id)ad;
- (void)splashAdDidClick:(id)ad;
- (void)splashAdDidClose:(id)ad;
- (void)interstitialAd:(id)ad didLoadWithExt:(NSDictionary *)ext;
- (void)interstitialAd:(id)ad didLoadFailWithError:(NSError *)error ext:(NSDictionary *)ext;
- (void)interstitialAdDidShowFailed:(id)ad error:(NSError *)error;
- (void)interstitialAdRenderSuccess:(id)ad;
- (void)interstitialAdDidVisible:(id)ad;
- (void)interstitialAdDidClick:(id)ad;
- (void)interstitialAdDidClose:(id)ad;
- (void)rewardedVideoAd:(id)ad didLoadWithExt:(NSDictionary *)ext;
- (void)rewardedVideoAd:(id)ad didLoadFailWithError:(NSError *)error ext:(NSDictionary *)ext;
- (void)rewardedVideoAdDidShowFailed:(id)ad error:(NSError *)error;
- (void)rewardedVideoAdVideoDidLoad:(id)ad;
- (void)rewardedVideoAdDidVisible:(id)ad;
- (void)rewardedVideoAdDidClick:(id)ad;
- (void)rewardedVideoAdDidClose:(id)ad;
- (void)rewardedVideoAd:(id)ad didPlayFinishWithError:(NSError *)error;
- (void)rewardedVideoAd:(id)ad didServerRewardSuccessWithInfo:(void (^)(BUMAdapterRewardAdInfo *))builder;
- (void)nativeAd:(id)ad didLoadWithExpressViews:(NSArray *)views exts:(NSArray *)exts;
- (void)nativeAd:(id)ad didLoadFailWithError:(NSError *)error;
- (void)nativeAd:(id)ad renderSuccessWithExpressView:(UIView *)view;
- (void)nativeAd:(id)ad renderFailWithExpressView:(UIView *)view andError:(NSError *)error;
- (void)nativeAd:(id)ad didClickWithMediatedNativeAd:(id)view;
- (void)nativeAd:(id)ad didVisibleWithMediatedNativeAd:(id)view;
- (void)nativeAd:(id)ad didCloseWithExpressView:(UIView *)view closeReasons:(NSArray *)reasons;
@end
@interface NSObject (GMTestBridgeStorage)
@property (nonatomic, strong) id<GMTestBridge> bridge;
@end
@protocol BUMCustomSplashAdapter <NSObject>
- (void)loadSplashAdWithSlotID:(NSString *)slotID andParameter:(NSDictionary *)parameter;
- (void)showSplashAdInWindow:(UIWindow *)window parameter:(NSDictionary *)parameter;
- (void)dismissSplashAd;
@end
@protocol BUMCustomInterstitialAdapter <NSObject>
- (void)loadInterstitialAdWithSlotID:(NSString *)slotID andSize:(CGSize)size parameter:(NSDictionary *)parameter;
- (BOOL)showAdFromRootViewController:(UIViewController *)vc parameter:(NSDictionary *)parameter;
@end
@protocol BUMCustomRewardedVideoAdapter <NSObject>
- (void)loadRewardedVideoAdWithSlotID:(NSString *)slotID andParameter:(NSDictionary *)parameter;
- (BOOL)showAdFromRootViewController:(UIViewController *)vc parameter:(NSDictionary *)parameter;
@end
@protocol BUMCustomNativeAdapter <NSObject>
- (void)loadNativeAdWithSlotID:(NSString *)slotID andSize:(CGSize)size imageSize:(CGSize)imageSize parameter:(NSDictionary *)parameter;
- (void)unregisterClickableViewsForNativeAd:(id)nativeAd;
@end
@protocol OSETSplashAdDelegate <NSObject>
@optional
- (void)splashDidReceiveSuccess:(id)ad slotId:(NSString *)slotId;
- (void)splashLoadToFailed:(id)ad error:(NSError *)error;
- (void)splashAdExposured:(id)ad;
- (void)splashAdExposuredToFailed:(id)ad error:(NSError *)error;
- (void)splashDidClose:(id)ad;
@end
@protocol OSETInterstitialAdDelegate <NSObject>
@optional
- (void)interstitialDidReceiveSuccess:(id)ad slotId:(NSString *)slotId;
- (void)interstitialLoadToFailed:(id)ad error:(NSError *)error;
@end
@protocol OSETRewardVideoAdDelegate <NSObject>
@optional
- (void)rewardVideoDidReceiveSuccess:(id)ad slotId:(NSString *)slotId;
- (void)rewardVideoLoadToFailed:(id)ad error:(NSError *)error;
@end
@protocol OSETNativeAdDelegate <NSObject>
@optional
- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)views;
- (void)nativeExpressAdDidExposured:(id)view;
@end
@interface OSETBaseAd : NSObject
@property NSInteger eCPM;
@property BOOL valid;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *reports;
- (BOOL)isAdValid;
@end
@interface OSETBaseView : UIView
@property NSInteger eCPM;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *reports;
@end
@interface OSETSplashAd : OSETBaseAd
@property (nonatomic, weak) id<OSETSplashAdDelegate> delegate;
@property (nonatomic, strong) UIWindow *shownWindow;
@property NSInteger dismissCount;
- (instancetype)initWithSlotId:(NSString *)slotID window:(UIWindow *)window bottomView:(UIView *)bottomView;
- (void)loadSplashAd;
- (void)showSplashAdWithWindow:(UIWindow *)window bottomView:(UIView *)bottomView;
@end
@interface OSETInterstitialAd : OSETBaseAd
@property (nonatomic, weak) id<OSETInterstitialAdDelegate> delegate;
- (instancetype)initWithSlotId:(NSString *)slotID;
- (void)loadInterstitialAdData;
- (void)showInterstitialFromRootViewController:(UIViewController *)vc;
@end
@interface OSETRewardVideoAd : OSETBaseAd
@property (nonatomic, weak) id<OSETRewardVideoAdDelegate> delegate;
@property (nonatomic, copy) NSString *userId;
- (instancetype)initWithSlotId:(NSString *)slotID withUserId:(NSString *)userID;
- (void)loadRewardAdData;
- (void)showRewardFromRootViewController:(UIViewController *)vc;
@end
@interface OSETNativeAd : OSETBaseAd
@property (nonatomic, weak) id<OSETNativeAdDelegate> delegate;
@property (nonatomic, weak) UIViewController *viewController;
- (instancetype)initWithSlotId:(NSString *)slotID size:(CGSize)size rootViewController:(UIViewController *)vc;
- (void)loadAdData;
@end
@interface GMBridgeSpy : NSObject <GMTestBridge>
@property (nonatomic, strong) UIViewController *vc;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@property (nonatomic, strong) NSDictionary *lastExt;
@property (nonatomic, strong) NSArray *views;
@property (nonatomic, strong) NSArray *exts;
@property (nonatomic, strong) id visibleView;
@property (nonatomic, copy) void (^onNativeLoad)(void);
- (NSUInteger)count:(NSString *)name;
@end
