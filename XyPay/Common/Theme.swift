//
//  Theme.swift
//  XyPay
//
//  颜色取自 Android res/values/colors.xml + themes.xml，
//  保证两端视觉基本一致（Material purple 主色）。
//

import SwiftUI

enum Theme {
    /// purple_500  主色
    static let primary = Color(hex: 0x6200EE)
    /// purple_700  主色深色变体
    static let primaryDark = Color(hex: 0x3700B3)
    /// purple_200
    static let primaryLight = Color(hex: 0xBB86FC)
    /// teal_200  次色
    static let secondary = Color(hex: 0x03DAC5)

    /// 页面背景（Material 默认 surface 近似值，浅色）
    static let surface = Color(hex: 0xFAFAFA)

    static let titleText = Color(hex: 0x1C1B1F)
    static let bodyText = Color(hex: 0x49454F)

    /// 主按钮渐变
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    /// 0xRRGGBB 形式快速构造颜色
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
