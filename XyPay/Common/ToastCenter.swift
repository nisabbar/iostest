//
//  ToastCenter.swift
//  XyPay
//
//  Android 有系统级 Toast，iOS 没有，这里用轻量 HUD 还原同样的交互：
//  短提示 2s、长提示 3.5s（对齐 Toast.LENGTH_SHORT / LENGTH_LONG）。
//

import SwiftUI

/// 注意：所有方法都必须在主线程调用（业务侧均在主线程回调，符合该约定）
final class ToastCenter: ObservableObject {

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let duration: TimeInterval
    }

    static let shared = ToastCenter()

    /// Toast.LENGTH_SHORT
    static let short: TimeInterval = 2.0
    /// Toast.LENGTH_LONG
    static let long: TimeInterval = 3.5

    @Published private(set) var current: Toast?

    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func show(_ text: String, duration: TimeInterval = ToastCenter.short) {
        dismissWorkItem?.cancel()

        let toast = Toast(text: text, duration: duration)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            current = toast
        }

        let item = DispatchWorkItem { [weak self] in
            guard let self, self.current?.id == toast.id else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                self.current = nil
            }
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }

    func showLong(_ text: String) {
        show(text, duration: ToastCenter.long)
    }

    func dismissImmediately() {
        dismissWorkItem?.cancel()
        current = nil
    }
}

/// 挂在页面底部（顶部 SafeArea 下方）的 Toast 容器
struct ToastHost: View {
    @EnvironmentObject private var center: ToastCenter

    var body: some View {
        VStack {
            Spacer()
            if let toast = center.current {
                Text(toast.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(hex: 0x2B2B2B).opacity(0.94))
                            .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                    )
                    .padding(.horizontal, 36)
                    .padding(.bottom, 56)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(toast.id)
            }
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: center.current?.id)
    }
}
