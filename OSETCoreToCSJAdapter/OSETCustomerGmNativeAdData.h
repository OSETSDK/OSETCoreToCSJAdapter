#import <BUAdSDK/BUAdSDK.h>
#import <OSETSDK/OSETSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// Converts public OSET native assets to the GroMore material contract.
@interface OSETCustomerGmNativeAdData : NSObject <BUMMediatedNativeAdData>
- (instancetype)initWithDataObject:(OSETNativeDataAdObject *)dataObject;
@end

NS_ASSUME_NONNULL_END
