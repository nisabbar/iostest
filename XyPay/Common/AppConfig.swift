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

    /// 与 Android 最新扫码页提示一致。
    static let scanPrompt = "将二维码完整放入画面，保持清晰并留出四周空白"
}

/// 统一文案，便于对齐 Android 的 Toast 内容
enum AppText {
    static let scanButton = "📷 扫码并自动支付"
    static let scanCancelled = "❌ 扫码取消"
    static let scanFailedNoOrderStr = "❌ 支付二维码格式不正确或参数不完整"
    static let scanSucceeded = "✅ 识别成功，自动拉起支付"
    static let selectPhoto = "选择相册扫码支付"
    static let recognizingPhoto = "正在识别照片中的二维码…"
    static let photoReadFailed = "无法读取或识别照片，请重新选择图片"
    static let photoNoQRCode = "未识别到二维码，请选择清晰、完整的二维码照片"
    static let cameraDenied = "相机权限被拒绝"

    static let paySuccess = "✅ 支付成功"
    static let payCancelled = "⚠️ 用户取消支付"
    static func payFailed(_ status: String) -> String { "❌ 支付失败: \(status)" }
}
