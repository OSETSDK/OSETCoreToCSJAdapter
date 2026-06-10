//
//  OSETCustomerGmInitAdapter.m
//  BUADDemo
//
//  Created by Shens on 5/3/2025.
//  Copyright © 2025 bytedance. All rights reserved.
//

#import "OSETCustomerGmInitAdapter.h"
#import <OSETSDK/OSETSDK.h>
@implementation OSETCustomerGmInitAdapter

/// 该自定义adapter是基于哪个版本实现的，填写编写时的最新值即可，GroMore会根据该值进行兼容处理
- (BUMCustomAdapterVersion *)basedOnCustomAdapterVersion {
    return BUMCustomAdapterVersion1_1;
}

/// adn初始化方法
/// @param initConfig 初始化配置，包括appid、appkey基本信息和部分用户传递配置
- (void)initializeAdapterWithConfiguration:(BUMSdkInitConfig *_Nullable)initConfig {
    /// 做一些ADN初始化的操作
    [OSETManager configure:initConfig.appID];
}

/// adapter的版本号
- (NSString *_Nonnull)adapterVersion {
    return @"1.0.0";
}

/// adn的版本号
- (NSString *_Nonnull)networkSdkVersion {
    return [OSETManager version];
}

/// 隐私权限更新，用户更新隐私配置时触发，初始化方法调用前一定会触发一次
- (void)didRequestAdPrivacyConfigUpdate:(NSDictionary *)config {
    /// 处理隐私问题
}

- (nonnull NSMutableDictionary *)adnInitInfo {
    return [[NSMutableDictionary alloc] initWithDictionary:@{@"status":@([OSETManager checkConfigure])}];
}

- (void)didReceiveConfigUpdateRequest:(nonnull BUMUserConfig *)config { 
    
}

@end
