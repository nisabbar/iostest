//
//  AppDelegate.swift
//  XyPay
//
//  SwiftUI 生命周期下仍需 AppDelegate 的两个场景：
//   1. 启动时做一次性配置
//   2. 兜底接收支付宝回跳 URL（老系统/非常规唤起路径下 application:openURL: 会先命中这里）
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NSLog("[XyPay] launched")
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        PaymentService.shared.handlePaymentCallback(url: url)
    }
}
