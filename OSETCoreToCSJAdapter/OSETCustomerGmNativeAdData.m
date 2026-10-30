#import "OSETCustomerGmNativeAdData.h"
#import <math.h>
#import <float.h>

static NSString *OSETGmNativeString(id value) {
    return [value isKindOfClass:NSString.class] && [value length] > 0 ? value : nil;
}

static CGFloat OSETGmNativeDimension(id value) {
    if (![value isKindOfClass:NSNumber.class] && ![value isKindOfClass:NSString.class]) { return 0; }
    double number = [value doubleValue];
    return isfinite(number) && number > 0 && number <= FLT_MAX ? number : 0;
}

static BUMImage *OSETGmNativeImage(id value, id width, id height) {
    NSString *string = OSETGmNativeString(value);
    NSURL *url = string ? [NSURL URLWithString:string] : nil;
    NSString *scheme = url.scheme.lowercaseString;
    if (!url.host.length || (![@"https" isEqual:scheme] && ![@"http" isEqual:scheme])) { return nil; }
    BUMImage *image = [BUMImage new];
    image.imageURL = url;
    image.width = OSETGmNativeDimension(width);
    image.height = OSETGmNativeDimension(height);
    image.scale = 1;
    return image;
}

@interface OSETCustomerGmNativeAdData ()
@property (nonatomic, strong) OSETNativeDataAdObject *dataObject;
@end

@implementation OSETCustomerGmNativeAdData

- (instancetype)initWithDataObject:(OSETNativeDataAdObject *)dataObject {
    if ((self = [super init])) { _dataObject = dataObject; }
    return self;
}

- (NSArray<BUMImage *> *)imageList {
    NSMutableArray *images = [NSMutableArray array];
    id values = self.dataObject.imageList;
    if ([values isKindOfClass:NSArray.class]) {
        for (id value in values) {
            if (![value isKindOfClass:NSDictionary.class]) { continue; }
            BUMImage *image = OSETGmNativeImage(value[@"url"], value[@"width"], value[@"height"]);
            if (image) { [images addObject:image]; }
        }
    }
    if (!images.count && self.dataObject.isVideoAd) {
        BUMImage *cover = OSETGmNativeImage(self.dataObject.coverUrl, self.dataObject.coverWidth, self.dataObject.coverHeight);
        if (cover) { [images addObject:cover]; }
    }
    return images.copy;
}

- (BUMMediatedNativeAdCallToType)callToType { return BUMMediatedNativeAdCallToTypeUnknown; }
- (BUMImage *)icon { return OSETGmNativeImage(self.dataObject.appIconUrl, nil, nil); }
- (BUMImage *)adLogo { return OSETGmNativeImage(self.dataObject.adIconUrl, nil, nil); }
- (BUMImage *)adTextLogo { return nil; }
- (NSString *)adTitle { return OSETGmNativeString(self.dataObject.title) ?: OSETGmNativeString(self.dataObject.appName); }
- (NSString *)adDescription { return OSETGmNativeString(self.dataObject.desc); }
- (NSString *)buttonText { return OSETGmNativeString(self.dataObject.buttonText); }
- (BUFeedADMode)imageMode {
    if (self.dataObject.isVideoAd) { return BUFeedVideoAdModeImage; }
    if (self.imageList.count > 1) { return BUFeedADModeGroupImage; }
    return self.imageList.count ? BUFeedADModeLargeImage : BUFeedADModeMediationUnknown;
}
- (NSString *)source { return nil; }
- (NSInteger)score { return -1; }
- (NSInteger)commentNum { return -1; }
- (NSInteger)appSize { return -1; }
- (NSInteger)videoDuration { return 0; }
// Cover dimensions are not a reliable measurement of the actual video.
- (CGFloat)videoAspectRatio { return 0; }
- (NSDictionary *)mediaExt { return nil; }
- (NSString *)appPrice { return nil; }
- (NSString *)advertiser { return nil; }
- (NSString *)brandName { return nil; }
- (NSArray<BUMDislikeReason *> *)dislikeReasons { return nil; }
- (NSString *)videoUrl { return nil; }
- (BOOL)allowCustomVideoPlayer { return NO; }
- (NSInteger)videoResolutionWidth { return 0; }
- (NSInteger)videoResolutionHeight { return 0; }

@end
