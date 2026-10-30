#import <BUAdSDK/BUAdSDK.h>
#import <OSETSDK/OSETSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// One creator owns one material, renderer and originating load object.
@interface OSETCustomerGmNativeAdViewCreator : NSObject <BUMMediatedNativeAdViewCreator>
@property (nonatomic, strong, readonly) OSETNativeDataAdObject *dataObject;
@property (nonatomic, strong, readonly) OSETNativeDataAd *loadedAd;
@property (nonatomic, strong, readonly) OSETNativeAdRenderer *renderer;
@property (nonatomic, assign, readonly, getter=isInvalidated) BOOL invalidated;
@property (nonatomic, assign, readonly) BOOL registered;
@property (nonatomic, weak, nullable) UIViewController *viewController;
- (instancetype)initWithDataObject:(OSETNativeDataAdObject *)dataObject
                         loadedAd:(OSETNativeDataAd *)loadedAd
                         renderer:(OSETNativeAdRenderer *)renderer;
- (BOOL)registerContainer:(UIView *)container clickableViews:(NSArray<UIView *> *)views;
- (void)unregisterViews;
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
