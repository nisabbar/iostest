//
//  OrderStrParser.swift
//  XyPay
//
//  对齐 Android 6555f7f 的 MainActivity.parseOrderStr。
//

import Foundation

enum OrderStrParser {

    // Java Pattern 的 \s 默认只匹配 ASCII 空白，保持两端接受范围一致。
    private static let fieldsPattern = try? NSRegularExpression(
        pattern: #"^"([^"&\r\n]+)"[ \t\n\x0B\f\r]*"([^"&\r\n]+)"[ \t\n\x0B\f\r]*"([^"&\r\n]+)"[ \t\n\x0B\f\r]*"([^"&\r\n]+)"$"#
    )
    private static let trimCharacters = CharacterSet(charactersIn: "\u{0000}"..."\u{0020}")

    static func parse(_ scanned: String) -> String {
        let text = scanned.trimmingCharacters(in: trimCharacters)
        guard !text.isEmpty else { return "" }

        // URL 优先；缺参数或解码失败时拒绝。
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            guard let range = text.range(of: "orderStr=") else { return "" }
            var value = String(text[range.upperBound...])
            if let amp = value.firstIndex(of: "&") {
                value = String(value[..<amp])
            }
            // 与 Android 一样直接返回解码结果，不再展开或二次解析。
            return urlDecode(value) ?? ""
        }

        if let expanded = expandCompactOrder(text) { return expanded }

        if text.contains("app_id=")
            || text.contains("method=alipay.trade.app.pay")
            || text.contains("service=mobile.securitypay.pay")
            || text.contains("service=\"mobile.securitypay.pay\"") {
            return text
        }

        return ""
    }

    /// 格式："extern_token值""sign_date值""trade_no值""sign值"。
    /// 双引号之间可有空白；值本身保持原样，尤其不能再次解码签名。
    private static func expandCompactOrder(_ text: String) -> String? {
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = fieldsPattern?.firstMatch(in: text, range: fullRange),
              match.range == fullRange else { return nil }
        let source = text as NSString
        let values = (1...4).map { source.substring(with: match.range(at: $0)) }
        guard values.allSatisfy({
            !$0.trimmingCharacters(in: trimCharacters).isEmpty
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
