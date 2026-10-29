//
//  OrderStrParser.swift
//  XyPay
//
//  支持四个双引号值的简写二维码，补齐固定支付参数。
//  完整订单串和 URL orderStr 参数保留原有处理。
//

import Foundation

enum OrderStrParser {

    static func parse(_ scanned: String) -> String {
        let text = scanned.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.hasPrefix("\"") {
            return expandCompactOrder(text)
        }

        // 1. 直接就是 orderStr
        if text.contains("app_id=")
            || text.contains("method=alipay.trade.app.pay")
            || text.contains("service=mobile.securitypay.pay") {
            return text
        }

        // 2. URL 里带 orderStr 参数
        if text.hasPrefix("http"), let range = text.range(of: "orderStr=") {
            var value = String(text[range.upperBound...])
            if let amp = value.firstIndex(of: "&") {
                value = String(value[..<amp])
            }
            // Android 解码抛异常后会回退到整段扫码内容。
            guard let decoded = urlDecode(value) else { return text }
            let compact = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            return compact.hasPrefix("\"") ? expandCompactOrder(compact) : decoded
        }

        // 3. 兜底：原样当 orderStr
        return text
    }

    /// 格式："extern_token值""sign_date值""trade_no值""sign值"。
    /// 双引号之间可有空白；值本身保持原样，尤其不能再次解码签名。
    private static func expandCompactOrder(_ text: String) -> String {
        let parts = text.components(separatedBy: "\"")
        // 四对引号拆出四个值和五段间隔，拒绝缺字段、额外字段或引号外杂项。
        guard parts.count == 9,
              stride(from: 0, to: parts.count, by: 2).allSatisfy({
                  parts[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
            return ""
        }

        let values = [parts[1], parts[3], parts[5], parts[7]]
        guard values.allSatisfy({
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !$0.contains("&")
        }) else {
            return ""
        }

        return [
            "_input_charset=\"UTF-8\"",
            "app_name=\"tb\"",
            "appenv=\"appid=taobao^system=null^version=5.0\"",
            "biz_type=\"trade\"",
            "extern_token=\"\(values[0])\"",
            "partner=\"PARTNER_TAOBAO_ORDER\"",
            "pay_user_mode=\"no_user\"",
            "service=\"mobile.securitypay.pay\"",
            "sign_date=\"\(values[1])\"",
            "trade_no=\"\(values[2])\"",
            "sign_type=\"DSA\"",
            "sign=\"\(values[3])\""
        ].joined(separator: "&")
    }

    /// 按表单 URL 编码处理：'+' 还原成空格，只解码一次。
    private static func urlDecode(_ value: String) -> String? {
        let normalized = value.replacingOccurrences(of: "+", with: " ")
        return normalized.removingPercentEncoding
    }
}
