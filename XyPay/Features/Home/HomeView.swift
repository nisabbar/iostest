//
//  HomeView.swift
//  XyPay
//
//  首页：对应 Android res/layout/activity_main.xml
//  Android 只有一个居中的 Material Button（"📷 扫码并自动支付"），
//  点击后申请相机权限 -> 扫码 -> 解析 orderStr -> 拉起支付宝 -> Toast 结果。
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var toast: ToastCenter

    @State private var showScanner = false
    @State private var pendingOrderStr: String?

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                badge

                VStack(spacing: 8) {
                    Text(AppConfig.appName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Theme.titleText)

                    Text("扫描支付宝支付二维码，自动拉起收银台")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.bodyText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 22)

                Spacer(minLength: 24)

                scanButton
            }
            .padding(.horizontal, 32)   // 对齐 Android padding 32dp
            .padding(.bottom, 16)
        }
        .overlay(ToastHost())
        .fullScreenCover(isPresented: $showScanner, onDismiss: payScannedOrder) {
            ScannerView(prompt: AppConfig.scanPrompt) { outcome in
                handle(outcome)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - 子视图

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.primaryGradient)
                .frame(width: 96, height: 96)
                .shadow(color: Theme.primary.opacity(0.32), radius: 20, y: 10)

            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 46, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var scanButton: some View {
        Button {
            showScanner = true
        } label: {
            Text(AppText.scanButton)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.primaryGradient)
                        .shadow(color: Theme.primary.opacity(0.35), radius: 16, y: 8)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - 扫码结果处理（对应 Android onActivityResult）

    private func handle(_ outcome: ScannerOutcome) {
        pendingOrderStr = nil
        showScanner = false

        switch outcome {
        case .cancelled:
            toast.show(AppText.scanCancelled)

        case .failure(let message):
            toast.showLong(message)

        case .scanned(let code):
            let orderStr = OrderStrParser.parse(code)
            guard !orderStr.isEmpty else {
                toast.showLong(AppText.scanFailedNoOrderStr)
                return
            }
            pendingOrderStr = orderStr
        }
    }

    /// 等扫码页关闭后再调用 SDK，避免收银台与扫码页的转场冲突。
    private func payScannedOrder() {
        guard let orderStr = pendingOrderStr else { return }
        pendingOrderStr = nil
        toast.show(AppText.scanSucceeded)
        PaymentService.shared.pay(orderStr: orderStr) { result in
            toast.show(result.displayMessage, duration: ToastCenter.long)
        }
    }
}

/// 按压反馈
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .environmentObject(ToastCenter.shared)
}
