//
//  OrderStrParser.swift
//  XyPay
//
//  参考 Android MainActivity#parseOrderStr，保留同样的判断顺序：
//   1. 扫码内容本身就是 orderStr（含 app_id= / method=alipay.trade.app.pay / service=mobile.securitypay.pay）
//   2. 是一个 http 链接，且带 orderStr= 参数  -> 取出并 URL 解码
//   3. 兜底：把整段内容当作 orderStr
//

import Foundation

enum OrderStrParser {

    static func parse(_ scanned: String) -> String {
        let text = scanned.trimmingCharacters(in: .whitespacesAndNewlines)

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
            return urlDecode(value) ?? text
        }

        // 3. 兜底：原样当 orderStr
        return text
    }

    /// 按表单 URL 编码处理：'+' 还原成空格，只解码一次。
    private static func urlDecode(_ value: String) -> String? {
        let normalized = value.replacingOccurrences(of: "+", with: " ")
        return normalized.removingPercentEncoding
    }
}
