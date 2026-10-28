//
//  AppConfig.swift
//  XyPay
//
//  全局常量：与 Android 侧 app/build.gradle、strings.xml 保持一致。
//

import Foundation

enum AppConfig {

    /// 应用名（Android: @string/app_name）
    static let appName = "xy_pay"

    /// Bundle Identifier（Android: applicationId）
    static let bundleIdentifier = "com.xy.demo.pay"

    /// 支付宝支付完成后回跳本 App 的 URL Scheme
    /// 必须与 Config/Info.plist -> CFBundleURLTypes -> CFBundleURLSchemes 一致
    static let alipayCallbackScheme = "xypay"

    /// 扫码页提示文案（Android: integrator.setPrompt("将支付二维码放入框内")）
    static let scanPrompt = "将支付二维码放入框内"
}

/// 统一文案，便于对齐 Android 的 Toast 内容
enum AppText {
    static let scanButton = "📷 扫码并自动支付"
    static let scanCancelled = "❌ 扫码取消"
    static let scanFailedNoOrderStr = "❌ 未识别到 orderStr"
    static let scanSucceeded = "✅ 扫码成功，自动拉起支付"
    static let cameraDenied = "相机权限被拒绝"

    static let paySuccess = "✅ 支付成功"
    static let payCancelled = "⚠️ 用户取消支付"
    static func payFailed(_ status: String) -> String { "❌ 支付失败: \(status)" }
}
