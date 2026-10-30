# OSETCoreToCSJAdapter

OSET 广告通过 GroMore 自定义 ADN 接入。GM 使用 Ads-CN-Beta；同目录的
OSETCoreToCSJAdapter 使用 Ads-CN。两套适配器具有相同的运行时类名，应用应择一集成。

## 信息流渲染类型

`BUMAdLoadingParamExpressAdType` 为 2 时使用 `OSETNativeDataAd` 自渲染；
为 1 时使用 `OSETNativeAd` 模板广告。0 或缺省值保留模板行为。
无效类型返回加载失败，不把自渲染失败静默切换成模板成功。

自渲染当前一次返回一条素材。宿主通过 GroMore 的 `BUMCanvasView` 自行布局，
使用其 `mediaView` 承载 SDK 视频，并注册真实容器及可点击元素。
广告位在 GroMore 后台的样式与 OSET 自渲染广告位必须匹配。

每条素材拥有独立的 Renderer、原始加载对象和视图创建对象。
曝光、点击和竞价通过原始素材对象匹配，不能用最后一个 View 或 Renderer 代替。
竞价通知逐次转交 OSETSDK，不在适配层去重；价格不可用时省略价格字段。
注销会清理点击、播放和事件绑定；过期或已关闭广告不可继续注册。

视频使用 SDK 的媒体视图，不开放原始视频 URL 或宿主自定义播放器。
未知时长、真实视频比例等素材字段使用协议缺省值，不用封面比例代替视频比例。
较早 OSET 版本可能没有视频开始/完成/错误回调，需按所用 SDK 和渠道验证事件覆盖。

## 本地 Demo 与测试

开发 Demo：`/Users/shens/Desktop/OSETGMDemo/OSETGMDemo.xcworkspace`。
当前 Demo 使用正式版 Ads-CN 与本地 CSJ 适配器，OSETCoreAd 使用 Podfile 解析的版本。
自渲染开发代码尚未发布，测试时应保留适配器的本地 `:path`：

```ruby
pod 'OSETCoreToCSJAdapter', :path => '../../CocoaPods/OSETCoreToCSJAdapter'
```

若改为 `pod 'OSETCoreToCSJAdapter', '7.0.0.0'`，会安装仅支持模板信息流的发布版，
本地自渲染代码不会进入 App。新增源文件或更改依赖后执行 `pod install --no-repo-update`，
并使用更新后的 `.xcworkspace` 构建。切换到 GM 时需同时使用本地 GM 适配器与 Ads-CN-Beta，
不要同时集成 GM 和 CSJ。

- `OSETGMDemo`：人工测试入口。
- `OSETGMDemoAdapterTests`：真实 SDK 类型下的受控加载、Renderer 和 bridge 行为回归。
- `OSETGMDemoLiveUITests`：打开自渲染页面并请求现有广告位，记录真实请求结果和截图。

`Tests/OSETGmNativeAdapterTests.m` 中的加载器和 Renderer 替身不产生真实广告请求，
其通过结果不代表线上填充、视频播放、计费或服务器收到竞价通知。
Live UI 测试只确认真实请求产生可观察结果，不将无填充视为广告接入成功。
`testHostAdapterIncludesSelfRenderingSupport` 另行检查宿主 App 实际集成的适配器，
防止测试包编译了本地源码、宿主却仍使用模板发布版时出现误判。

Demo 的 `OSET_GM_FORCE_CHANNEL` 启动环境变量可覆盖原有手动渠道选择，空字符串表示不强制渠道。
单元测试 Scheme 使用 `OSET_GM_UNIT_TESTS=1` 隔离手动强制渠道，普通运行不设置该变量。
