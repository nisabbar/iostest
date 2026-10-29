//
//  PaymentResult.swift
//  XyPay
//
//  对应 Android 侧 payTask.payV2() 返回的 Map<String, String>。
//

import Foundation

struct PaymentResult: Identifiable {

    let id = UUID()

    /// resultStatus：9000 成功 / 6001 用户取消 / 其他为失败
    let status: String
    /// memo：SDK 给的说明文字
    let memo: String
    /// result：同步返回的原始业务串（一般需要回服务端验签）
    let result: String

    let raw: [String: Any]

    init(dictionary: [String: Any]?) {
        let dict = dictionary ?? [:]
        status = (dict["resultStatus"] as? String) ?? "未返回"
        memo = (dict["memo"] as? String) ?? ""
        result = (dict["result"] as? String) ?? ""
        raw = dict
    }

    init(status: String, memo: String) {
        self.status = status
        self.memo = memo
        self.result = ""
        self.raw = ["resultStatus": status, "memo": memo]
    }

    var isSuccess: Bool { status == "9000" }
    var isCancelled: Bool { status == "6001" }

    var failureDetails: String {
        let explanation = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "SDK 未提供详细说明" : memo
        return "返回码（resultStatus）：\(status)\n返回说明（memo）：\(explanation)"
    }

    /// 状态码中文含义（仅用于日志/调试）
    var statusDescription: String {
        switch status {
        case "9000": return "支付成功"
        case "8000": return "正在处理中，支付结果未知"
        case "4000": return "订单支付失败"
        case "5000": return "重复请求"
        case "6001": return "用户中途取消"
        case "6002": return "网络连接出错"
        case "6004": return "支付结果未知"
        default:     return "未知状态"
        }
    }

    /// Toast 文案，与 Android 三个分支一致。
    var displayMessage: String {
        if isSuccess {
            return AppText.paySuccess
        }
        if isCancelled { return AppText.payCancelled }
        return AppText.payFailed(status)
    }
}
