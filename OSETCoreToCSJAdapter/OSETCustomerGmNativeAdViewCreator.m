#import "OSETCustomerGmNativeAdViewCreator.h"
#import <OSETSDK/OSETMediaView.h>

@interface OSETGmNativeMediaContainer : UIView
@property (nonatomic, strong) UIView *contentView;
@end
@implementation OSETGmNativeMediaContainer
- (void)setContentView:(UIView *)view {
    if (_contentView == view) { return; }
    [_contentView removeFromSuperview];
    _contentView = view;
    if (view) { [self addSubview:view]; [self setNeedsLayout]; }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
}
@end

@interface OSETCustomerGmNativeAdViewCreator ()
@property (nonatomic, strong) OSETNativeDataAdObject *dataObject;
@property (nonatomic, strong) OSETNativeDataAd *loadedAd;
@property (nonatomic, strong) OSETNativeAdRenderer *renderer;
@property (nonatomic, assign, getter=isInvalidated) BOOL invalidated;
@property (nonatomic, strong) OSETGmNativeMediaContainer *mediaContainer;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) NSUInteger registrationGeneration;
@property (nonatomic, assign) BOOL registered;
@property (nonatomic, weak) UIView *registeredContainer;
@end

@implementation OSETCustomerGmNativeAdViewCreator

- (instancetype)initWithDataObject:(OSETNativeDataAdObject *)dataObject
                         loadedAd:(OSETNativeDataAd *)loadedAd
                         renderer:(OSETNativeAdRenderer *)renderer {
    if ((self = [super init])) {
        _dataObject = dataObject;
        _loadedAd = loadedAd;
        _renderer = renderer;
        _renderer.dataObject = dataObject;
    }
    return self;
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;
    self.loadedAd.viewController = viewController;
    self.renderer.viewController = viewController;
}

- (BOOL)registerContainer:(UIView *)container clickableViews:(NSArray<UIView *> *)views {
    if (self.invalidated || ![container isKindOfClass:UIView.class] || !self.dataObject.isAdValid) { return NO; }
    NSMutableArray<UIView *> *validViews = [NSMutableArray array];
    for (id view in ([views isKindOfClass:NSArray.class] ? views : @[])) {
        if ([view isKindOfClass:UIView.class] && (view == container || [view isDescendantOfView:container])) {
            [validViews addObject:view];
        }
    }
    NSUInteger generation = ++self.registrationGeneration;
    BOOL sameContainer = self.registered && self.registeredContainer == container && self.renderer.dataObject == self.dataObject;
    if (!sameContainer) {
        self.renderer.dataObject = self.dataObject;
        self.registered = YES;
        self.registeredContainer = container;
        [self.renderer registerContainerView:container withDataObject:self.dataObject];
    }
    // Registration can synchronously expose/close the ad and reenter the bridge.
    if (self.invalidated || generation != self.registrationGeneration) { return NO; }
    [self.renderer registerClickableViews:validViews];
    if (self.invalidated || generation != self.registrationGeneration) { return NO; }
    if ([self.closeButton isDescendantOfView:container]) {
        [self.renderer registerCloseView:self.closeButton];
    }
    if (self.invalidated || generation != self.registrationGeneration) { return NO; }
    [self refreshMediaView];
    return YES;
}

- (void)refreshMediaView {
    if (self.invalidated || !self.dataObject.isVideoAd) { return; }
    if (!self.mediaContainer) { self.mediaContainer = [OSETGmNativeMediaContainer new]; }
    self.mediaContainer.contentView = self.renderer.mediaView;
    if ([self.mediaContainer.contentView isKindOfClass:OSETMediaView.class]) {
        [(OSETMediaView *)self.mediaContainer.contentView muteEnable:self.loadedAd.videoMuted];
    }
}

- (void)unregisterViews {
    ++self.registrationGeneration;
    self.registered = NO;
    self.registeredContainer = nil;
    [self.renderer unregisterDataObject];
    self.mediaContainer.contentView = nil;
}

- (void)invalidate {
    if (self.invalidated) { return; }
    self.invalidated = YES;
    self.renderer.delegate = nil;
    [self unregisterViews];
}

- (UIView *)mediaView {
    if (self.invalidated || !self.dataObject.isVideoAd) { return nil; }
    [self refreshMediaView];
    return self.mediaContainer;
}
- (UIButton *)dislikeBtn {
    if (!self.closeButton) {
        self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
        self.closeButton.accessibilityLabel = @"关闭广告";
    }
    return self.closeButton;
}
- (BOOL)hasSupportActionBtn { return YES; }
- (UILabel *)titleLabel { return nil; }
- (UILabel *)descLabel { return nil; }
- (UIImageView *)iconImageView { return nil; }
- (UIImageView *)imageView { return nil; }
- (UIButton *)callToActionBtn { return nil; }
- (UIView *)advertiserView { return nil; }
- (UIView *)ecMallView { return nil; }
- (UIView *)adLogoView { return nil; }

- (void)dealloc {
    OSETNativeAdRenderer *renderer = _renderer;
    if (NSThread.isMainThread) {
        renderer.delegate = nil;
        [renderer unregisterDataObject];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            renderer.delegate = nil;
            [renderer unregisterDataObject];
        });
    }
}

@end
