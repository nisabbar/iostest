//
//  PaymentService.swift
//  XyPay
//
//  支付流程的唯一入口。
//  Android：new Thread { payTask.payV2(orderStr, true) } -> Handler 回主线程
//  iOS    ：AlipayBridge(payOrder) -> 主线程回调；支付宝 App 回跳时走 handlePaymentCallback
//

import Foundation
import Combine

final class PaymentService: ObservableObject {

    static let shared = PaymentService()

    @Published var failure: PaymentResult?

    private init() {}

    /// 普通回调和冷启动备用回调共用同一套展示逻辑。
    func present(_ result: PaymentResult) {
        if result.isSuccess || result.isCancelled {
            failure = nil
            ToastCenter.shared.showLong(result.displayMessage)
        } else {
            ToastCenter.shared.dismissImmediately()
            failure = result
        }
    }

    // MARK: - 发起支付

    /// 从主线程调用，与 Android 一样直接把订单串交给 SDK。
    func pay(orderStr: String, completion: @escaping (PaymentResult) -> Void) {
        let trimmed = orderStr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(PaymentResult(status: "-1", memo: "orderStr 为空"))
            return
        }

        AlipayBridge.pay(orderString: trimmed,
                         scheme: AppConfig.alipayCallbackScheme) { dictionary in
            let result = PaymentResult(dictionary: dictionary)
            NSLog("[XY_PAY] resultStatus=%@", result.status)
            completion(result)
        }
    }

    // MARK: - 支付宝回跳

    /// - Returns: 该 URL 是否属于支付宝支付回跳。
    @discardableResult
    func handlePaymentCallback(url: URL) -> Bool {
        guard url.scheme?.lowercased() == AppConfig.alipayCallbackScheme.lowercased(),
              url.host?.lowercased() == "safepay" else {
            return false
        }
        // SDK 优先调用 payOrder 的原回调；App 被回收等情况下走 standbyCallback。
        // 备用回调写入共享展示状态，不依赖已丢失的页面闭包。
        AlipayBridge.handleOpenURL(url) { dictionary in
            let result = PaymentResult(dictionary: dictionary)
            NSLog("[XY_PAY] standby resultStatus=%@", result.status)
            self.present(result)
        }
        return true
    }
}
