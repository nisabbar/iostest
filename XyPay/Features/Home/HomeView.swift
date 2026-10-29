//
//  HomeView.swift
//  XyPay
//
//  首页：对应 Android res/layout/activity_main.xml
//  相机扫码 / 相册识别 -> 统一解析 orderStr -> 拉起支付宝 -> 展示结果。
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var toast: ToastCenter

    @ObservedObject private var payment = PaymentService.shared

    private enum Source: String, Identifiable {
        case camera, photo
        var id: String { rawValue }
    }

    @State private var source: Source?
    @State private var pendingOrderStr: String?
    @State private var pendingPhoto: NSItemProvider?
    @State private var recognizingPhoto = false

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

                    Text("扫描或选择支付宝支付二维码，自动拉起收银台")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.bodyText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 22)

                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    if recognizingPhoto {
                        ProgressView(AppText.recognizingPhoto)
                            .font(.system(size: 14))
                    }
                    photoButton
                    scanButton
                }
                .disabled(recognizingPhoto)
            }
            .padding(.horizontal, 32)   // 对齐 Android padding 32dp
            .padding(.bottom, 16)
        }
        .overlay(ToastHost())
        .fullScreenCover(item: $source, onDismiss: sourceDismissed) { selectedSource in
            switch selectedSource {
            case .camera:
                ScannerView(prompt: AppConfig.scanPrompt) { outcome in
                    handle(outcome)
                }
                .ignoresSafeArea()
            case .photo:
                PhotoQRCodePicker { provider in
                    pendingPhoto = provider
                }
            }
        }
        .alert(item: $payment.failure) { result in
            Alert(title: Text("支付未完成"),
                  message: Text(result.failureDetails),
                  dismissButton: .default(Text("确定")))
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
            source = .camera
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

    private var photoButton: some View {
        Button {
            source = .photo
        } label: {
            Label(AppText.selectPhoto, systemImage: "photo.on.rectangle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.primary, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - 扫码结果处理（对应 Android onActivityResult）

    private func handle(_ outcome: ScannerOutcome) {
        pendingOrderStr = nil
        source = nil

        switch outcome {
        case .cancelled:
            toast.show(AppText.scanCancelled)

        case .failure(let message):
            toast.showLong(message)

        case .scanned(let code):
            preparePayment(code)
        }
    }

    /// 等选择器或扫码页关闭后再处理，避免与支付宝收银台转场冲突。
    private func sourceDismissed() {
        guard let provider = pendingPhoto else {
            payScannedOrder()
            return
        }
        pendingPhoto = nil
        recognizingPhoto = true
        toast.show(AppText.recognizingPhoto)
        PhotoQRCodeDecoder.decode(provider) { result in
            recognizingPhoto = false
            switch result {
            case .success(let code):
                preparePayment(code)
                payScannedOrder()
            case .failure(let error):
                toast.showLong(error.localizedDescription)
            }
        }
    }

    private func preparePayment(_ code: String) {
        pendingOrderStr = nil
        let orderStr = OrderStrParser.parse(code)
        guard !orderStr.isEmpty else {
            toast.showLong(AppText.scanFailedNoOrderStr)
            return
        }
        pendingOrderStr = orderStr
    }

    private func payScannedOrder() {
        guard let orderStr = pendingOrderStr else { return }
        pendingOrderStr = nil
        toast.show(AppText.scanSucceeded)
        PaymentService.shared.pay(orderStr: orderStr) { result in
            payment.present(result)
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
