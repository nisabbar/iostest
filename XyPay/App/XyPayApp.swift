//
//  XyPayApp.swift
//  XyPay
//

import SwiftUI

@main
struct XyPayApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var toastCenter = ToastCenter.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(toastCenter)
                // 支付宝 App 支付完成后回跳本 App，URL 需要交回 SDK 才能拿到真实结果
                .onOpenURL { url in
                    let handled = PaymentService.shared.handlePaymentCallback(url: url)
                    NSLog("[XyPay] openURL=\(url.absoluteString) handled=\(handled)")
                }
                // 界面配色按 Material 浅色主题硬编码，固定浅色避免深色模式下对比度异常
                .preferredColorScheme(.light)
        }
    }
}
