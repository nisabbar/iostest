# XyPay iOS Demo

参考 `xy_pay` Android 项目的扫码支付 Demo，最低支持 iOS 15。

主要流程：点击「📷 扫码并自动支付」→ 相机扫码 → 提取 `orderStr` → 调用支付宝 SDK → 显示支付结果。

## 与 Android 的参数对应

| Android | iOS |
| --- | --- |
| ZXing 扫二维码 | AVFoundation 扫二维码 |
| `MainActivity.parseOrderStr` | `OrderStrParser.parse` |
| `PayTask.payV2(orderStr, true)` | `AlipaySDK.payOrder:fromScheme:callback:` |
| `resultStatus = 9000` | 显示「✅ 支付成功」 |
| `resultStatus = 6001` | 显示「⚠️ 用户取消支付」 |
| 其他状态码 | 显示「❌ 支付失败: 状态码」 |

二维码仍由原来的系统生成，iOS 不自行下单或签名：

1. 内容含 `app_id=`、`method=alipay.trade.app.pay` 或 `service=mobile.securitypay.pay` 时，按 Android 的判断顺序直接使用。
2. 以 `http` 开头并含 `orderStr=` 时，提取到下一个 `&` 为止，只做一次 URL 解码；外层编码里的 `+` 还原为空格。
3. 非法百分号编码无法解码时，回退到整段扫码内容；其他内容也按 Android 原样交给 SDK。

直接传入的订单串不会被额外解码、重签或重排参数，避免改变原签名。普通收款码不会自动转换成 APP 支付订单。

回跳 Scheme 为 `xypay`，在 `Config/Info.plist` 和 `XyPay/Common/AppConfig.swift` 中保持一致。SDK 的普通回调和备用回调都处理支付结果。本 Demo 不添加服务端查单、本地订单管理或自定义支付超时。

## 没有 Mac：使用 GitHub Actions 云打包

项目已提供 `.github/workflows/build-ipa.yml`，手动触发后在 GitHub 的 macOS 机器上安装依赖、构建真机 Release 包，并上传未签名 IPA。不需要本地 Mac，也不需要在仓库配置 Apple 账号或证书。

1. 建立 GitHub 私有仓库，把本目录内容放在仓库根目录，包括隐藏的 `.github` 目录。
2. 在仓库默认分支上传配置后，进入 **Actions → Build unsigned IPA → Run workflow**。
3. 构建成功后，在本次运行的 **Artifacts** 中下载 `XyPay-unsigned-ipa`。
4. 如果下载的是 ZIP，解压得到 `XyPay-unsigned.ipa`，交给对方自签安装。
5. 构建失败时查看对应步骤日志；`XyPay-build-details` 保留构建日志和本次依赖锁文件，保留时间为 7 天。

工作流没有 push 或定时触发，只在手动运行时构建；不发布 Release、不上传 App Store。配置使用 `macos-15-intel` 和 Xcode 16.4。

GitHub 私有仓库的云构建会使用账号的 Actions 配额，超出免费额度可能收费，具体以 [GitHub 计费说明](https://docs.github.com/en/actions/concepts/billing-and-usage) 为准。当前只准备了配置，尚未上传或运行云构建，没有生成 IPA。

## 在 Mac 上准备依赖

需要完整 Xcode 16 或更新版本，以及支持该工程同步文件组格式的 CocoaPods（例如 1.16.2 / Xcodeproj 1.27.0）。

在 Mac 上进入复制后的 `ios` 工程目录，再执行：

```bash
pod install
open XyPay.xcworkspace
```

支付宝 SDK 是必需依赖，版本固定为 `AlipaySDK-iOS 15.8.30`，没有模拟支付分支。未安装依赖或打开错误工程时，缺少 SDK 会直接报错，不会生成假支付功能。

首次安装生成的 `Podfile.lock` 应保留并纳入 Git；此文件不再被 `.gitignore` 忽略。没有在 Windows 上生成锁文件或下载 SDK。

参考：[SDK 的 CocoaPods 页面](https://cocoapods.org/pods/AlipaySDK-iOS)、[CocoaPods 依赖与锁文件说明](https://guides.cocoapods.org/using/using-cocoapods.html)。

## 生成给对方自签的未签名 IPA

以下命令仅为交付操作说明，本次源码修改没有执行这些命令，也没有生成 IPA。

不走 App Store 导出流程。由 Mac 构建真机版本，关闭此次构建的签名，将 `.app` 按 `Payload/XyPay.app` 结构打包，再由对方的签名工具签名安装。这一步不需要先填写分发 Team 或配置分发证书。

依赖安装完成后，在工程目录下执行下面整个命令块。使用独立输出目录，构建失败会停止，避免误交付旧包：

```bash
(
  set -e
  mkdir -p build
  package_dir=$(mktemp -d "$PWD/build/unsigned-XXXXXX")

  xcodebuild \
    -workspace XyPay.xcworkspace \
    -scheme XyPay \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$package_dir/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

  mkdir -p "$package_dir/Payload"
  ditto "$package_dir/DerivedData/Build/Products/Release-iphoneos/XyPay.app" \
        "$package_dir/Payload/XyPay.app"
  cd "$package_dir"
  /usr/bin/zip -qry XyPay-unsigned.ipa Payload
  printf '未签名 IPA：%s/XyPay-unsigned.ipa\n' "$package_dir"
)
```

输出位置由最后一行打印，例如 `ios/build/unsigned-ABC123/XyPay-unsigned.ipa`。

未签名 IPA 不能直接安装，须由对方使用有效的签名配置处理后安装。签名时保留 `xypay` URL Scheme，否则支付宝支付后无法按现有配置回到 Demo。使用真机包，不能把模拟器 `.app` 打包后交付。

如果选择自己签名后分发，则在 Xcode 中设置 Team，并按 [Apple 的归档及分发流程](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices) 操作；这是另一种交付方式。

## 真机确认

本次未运行编译或测试。拿到签名后的包后，用安装支付宝的 iPhone 确认：

- 首次授权相机、拒绝授权、取消扫码的提示。
- 扫原系统生成的有效订单二维码，可以拉起支付宝收银台。
- 支付完成或取消后，回到 Demo 显示对应结果。
- 扫码页切到后台再返回后，能够继续扫码。

界面使用 iOS 原生实现，不要求与 Android 外观一致。保留手电筒、扫码提示音和触觉反馈。
