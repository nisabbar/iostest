//
//  QRScannerViewController.swift
//  XyPay
//
//  AVFoundation 二维码扫描页。
//  对应 Android：IntentIntegrator + zxing-android-embedded 的 CaptureActivity
//     - 全画面识别，不限中央提示框
//     - setBeepEnabled(true)
//     - setDesiredBarcodeFormats(QR_CODE)
//     - 竖屏
//

import AVFoundation
import UIKit
import AudioToolbox

final class QRScannerViewController: UIViewController {

    // MARK: - 回调

    /// 扫到二维码，交给 OrderStrParser 统一处理。
    var onScanned: ((String) -> Void)?
    /// 用户点了关闭
    var onCancel: (() -> Void)?
    /// 相机不可用 / 权限被拒
    var onFailure: ((String) -> Void)?

    // MARK: - 属性

    private let promptText: String
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.xy.demo.pay.scanner.session")

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlay = ScannerOverlayView()

    private var isSessionConfigured = false
    private var isVisible = false
    private var hasFinished = false

    // MARK: - 初始化

    init(prompt: String) {
        self.promptText = prompt
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.promptText = promptText
        overlay.onCancel = { [weak self] in self?.handleCancel() }
        overlay.onTorchToggle = { [weak self] in self?.toggleTorch() }
        view.addSubview(overlay)

        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleDidEnterBackground),
                                              name: UIApplication.didEnterBackgroundNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleDidBecomeActive),
                                              name: UIApplication.didBecomeActiveNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleSessionInterruptionEnded),
                                              name: AVCaptureSession.interruptionEndedNotification,
                                              object: session)

        requestCameraAndConfigure()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        stopRunning()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlay.frame = view.bounds
        overlay.setNeedsLayout()
        updatePreviewOrientation()
    }

    // MARK: - 权限

    private func requestCameraAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self, !self.hasFinished else { return }
                    if granted {
                        self.configureSession()
                    } else {
                        self.finishWithFailure(AppText.cameraDenied)
                    }
                }
            }

        default:
            // .denied / .restricted
            finishWithFailure(AppText.cameraDenied)
        }
    }

    // MARK: - 会话配置

    private func configureSession() {
        guard !isSessionConfigured else {
            startRunning()
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.finishWithFailure("无法访问相机") }
                return
            }
            self.session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.finishWithFailure("无法识别二维码") }
                return
            }
            self.session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // 只识别二维码（对应 setDesiredBarcodeFormats(QR_CODE)）
            let available = output.availableMetadataObjectTypes
            guard available.contains(.qr) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.finishWithFailure("无法识别二维码") }
                return
            }
            output.metadataObjectTypes = [.qr]
            output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                guard !self.hasFinished else { return }
                self.isSessionConfigured = true
                self.attachPreviewLayer()
                self.overlay.isTorchOn = device.torchMode == .on
                self.startRunning()
            }
        }
    }

    private func attachPreviewLayer() {
        guard previewLayer == nil else { return }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        updatePreviewOrientation()
    }

    private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection else { return }
        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        } else {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }

    private func startRunning() {
        guard isSessionConfigured, isVisible, !hasFinished,
              UIApplication.shared.applicationState == .active else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    private func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    @objc private func handleDidEnterBackground() {
        stopRunning()
    }

    @objc private func handleDidBecomeActive() {
        startRunning()
    }

    @objc private func handleSessionInterruptionEnded() {
        DispatchQueue.main.async { [weak self] in
            self?.startRunning()
        }
    }

    // MARK: - 手电筒

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
            overlay.isTorchOn = device.torchMode == .on
        } catch {
            NSLog("[XyPay] torch toggle failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 结果

    private func handleCancel() {
        guard !hasFinished else { return }
        hasFinished = true
        stopRunning()
        onCancel?()
    }

    private func finishWithFailure(_ message: String) {
        guard !hasFinished else { return }
        hasFinished = true
        stopRunning()
        onFailure?(message)
    }

    private func finish(with code: String) {
        guard !hasFinished else { return }
        hasFinished = true
        stopRunning()
        playFeedback()
        onScanned?(code)
    }

    /// 对应 setBeepEnabled(true)：提示音 + 振动
    private func playFeedback() {
        AudioServicesPlaySystemSound(1057)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasFinished, isVisible,
              UIApplication.shared.applicationState == .active,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else {
            return
        }
        NSLog("[XY_SCAN] scanned=\(value)")
        finish(with: value)
    }
}
