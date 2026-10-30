Pod::Spec.new do |s|
  s.name         = "OSETCoreToCSJAdapter"
  s.version      = "7.0.3.0"
  s.summary      = "AdSet广告对接CSJ适配器"
  s.description  = <<-DESC
                    OSETSDK 是一个专业的广告聚合SDK，提供高效的广告展示和收益优化功能。
                    DESC
  s.homepage     = "https://github.com/OSETSDK/OSETCoreToGMAdapter"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { 'shenshi' => 'yaohaofei@shenshiads.com' }
  
  # 设置最低支持版本
  s.ios.deployment_target = '12.0'
  s.static_framework = true
  # 源文件配置
  s.source       = {
    :git => 'https://github.com/OSETSDK/OSETCoreToCSJAdapter.git',
    :tag => s.version.to_s
  }
  # 主框架文件
  # 检查 OSETCoreToGMAdapter.podspec 关键字段
  s.source_files = 'OSETCoreToCSJAdapter/**/*.{h,m}'
  # 系统框架依赖
  s.frameworks = "Foundation", "UIKit", "AdSupport", "CoreTelephony", "StoreKit", "SystemConfiguration"
  
  # 资源文件
    
  # Swift版本设置
  s.swift_version = '5.0'
  
  # ================= 第三方依赖库 =================
 
  s.dependency 'OSETCoreAd','>=7.0.0.0'
  s.dependency 'Ads-CN/BUAdSDK'
  s.dependency 'Ads-CN/CSJMediation'
end
