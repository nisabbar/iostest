//
//  ScannerOverlayView.swift
//  XyPay
//
//  扫码页蒙层：暗角、取景框四角、扫描线动画、提示文案、关闭/手电筒按钮。
//  （Android 侧这段由 zxing-android-embedded 自带的 CaptureActivity 提供）
//

import UIKit

final class ScannerOverlayView: UIView {

    var onCancel: (() -> Void)?
    var onTorchToggle: (() -> Void)?

    var promptText: String = "" {
        didSet { promptLabel.text = promptText }
    }

    var isTorchOn: Bool = false {
        didSet { updateTorchIcon() }
    }

    // MARK: - 子视图

    private let dimView = UIView()
    private let maskLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()
    private let scanLine = UIView()
    private let promptLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let torchButton = UIButton(type: .system)

    private let accentColor = UIColor(red: 0.73, green: 0.53, blue: 0.99, alpha: 1.0)

    // MARK: - 布局参数

    private let scanSideRatio: CGFloat = 0.68
    private let maxScanSide: CGFloat = 300

    /// 取景框（相对自身坐标系）
    var scanRect: CGRect {
        let side = min(bounds.width * scanSideRatio, min(bounds.height * 0.45, maxScanSide))
        let available = max(bounds.height - max(safeAreaInsets.top, 20) - max(safeAreaInsets.bottom, 20), side)
        let centerY = max(safeAreaInsets.top, 20) + available / 2
        return CGRect(x: (bounds.width - side) / 2,
                      y: centerY - side / 2,
                      width: side,
                      height: side)
    }

    // MARK: - 生命周期

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false

        // 暗色蒙层 + 中间镂空
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        dimView.isUserInteractionEnabled = false
        dimView.layer.mask = maskLayer
        addSubview(dimView)

        // 取景框四角
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 3
        borderLayer.lineCap = .round
        borderLayer.lineJoin = .round
        layer.addSublayer(borderLayer)

        // 扫描线
        scanLine.backgroundColor = accentColor.withAlphaComponent(0.95)
        scanLine.layer.cornerRadius = 1
        scanLine.layer.shadowColor = accentColor.cgColor
        scanLine.layer.shadowRadius = 8
        scanLine.layer.shadowOpacity = 0.9
        scanLine.layer.shadowOffset = .zero
        addSubview(scanLine)

        // 提示文案
        promptLabel.textColor = .white
        promptLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        promptLabel.textAlignment = .center
        promptLabel.numberOfLines = 2
        promptLabel.layer.shadowColor = UIColor.black.cgColor
        promptLabel.layer.shadowOpacity = 0.6
        promptLabel.layer.shadowRadius = 4
        promptLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(promptLabel)

        // 关闭
        styleFloatingButton(cancelButton,
                            symbol: "xmark",
                            pointSize: 16,
                            weight: .semibold)
        cancelButton.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)
        addSubview(cancelButton)

        // 手电筒
        styleFloatingButton(torchButton,
                            symbol: "bolt.fill",
                            pointSize: 18,
                            weight: .semibold)
        torchButton.addAction(UIAction { [weak self] _ in self?.onTorchToggle?() }, for: .touchUpInside)
        addSubview(torchButton)
    }

    private func styleFloatingButton(_ button: UIButton, symbol: String, pointSize: CGFloat, weight: UIImage.SymbolWeight) {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
    }

    private func updateTorchIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let name = isTorchOn ? "bolt.slash.fill" : "bolt.fill"
        torchButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
        torchButton.backgroundColor = isTorchOn
            ? accentColor.withAlphaComponent(0.85)
            : UIColor.black.withAlphaComponent(0.38)
    }

    // MARK: - 布局

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        dimView.frame = bounds

        let rect = scanRect

        let holePath = UIBezierPath(rect: bounds)
        holePath.append(UIBezierPath(roundedRect: rect, cornerRadius: 20))
        holePath.usesEvenOddFillRule = true

        maskLayer.frame = bounds
        maskLayer.path = holePath.cgPath
        maskLayer.fillRule = .evenOdd

        borderLayer.frame = bounds
        borderLayer.path = cornerPath(in: rect).cgPath

        promptLabel.frame = CGRect(x: 24, y: rect.minY - 44, width: bounds.width - 48, height: 34)

        let topInset = max(safeAreaInsets.top, 20)
        let bottomInset = max(safeAreaInsets.bottom, 20)

        cancelButton.frame = CGRect(x: 20, y: topInset + 6, width: 44, height: 44)
        torchButton.frame = CGRect(x: (bounds.width - 44) / 2,
                                  y: bounds.height - bottomInset - 64,
                                  width: 44,
                                  height: 44)

        scanLine.frame = CGRect(x: rect.minX + 12,
                                y: rect.minY + 2,
                                width: rect.width - 24,
                                height: 2)

        restartScanLineAnimation()
    }

    private func cornerPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let lineLength: CGFloat = 28
        let radius: CGFloat = 20
        let box = rect.insetBy(dx: 1.5, dy: 1.5)

        // 左上
        path.move(to: CGPoint(x: box.minX, y: box.minY + lineLength))
        path.addLine(to: CGPoint(x: box.minX, y: box.minY + radius))
        path.addQuadCurve(to: CGPoint(x: box.minX + radius, y: box.minY),
                          controlPoint: CGPoint(x: box.minX, y: box.minY))
        path.addLine(to: CGPoint(x: box.minX + lineLength, y: box.minY))

        // 右上
        path.move(to: CGPoint(x: box.maxX - lineLength, y: box.minY))
        path.addLine(to: CGPoint(x: box.maxX - radius, y: box.minY))
        path.addQuadCurve(to: CGPoint(x: box.maxX, y: box.minY + radius),
                          controlPoint: CGPoint(x: box.maxX, y: box.minY))
        path.addLine(to: CGPoint(x: box.maxX, y: box.minY + lineLength))

        // 右下
        path.move(to: CGPoint(x: box.maxX, y: box.maxY - lineLength))
        path.addLine(to: CGPoint(x: box.maxX, y: box.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: box.maxX - radius, y: box.maxY),
                          controlPoint: CGPoint(x: box.maxX, y: box.maxY))
        path.addLine(to: CGPoint(x: box.maxX - lineLength, y: box.maxY))

        // 左下
        path.move(to: CGPoint(x: box.minX + lineLength, y: box.maxY))
        path.addLine(to: CGPoint(x: box.minX + radius, y: box.maxY))
        path.addQuadCurve(to: CGPoint(x: box.minX, y: box.maxY - radius),
                          controlPoint: CGPoint(x: box.minX, y: box.maxY))
        path.addLine(to: CGPoint(x: box.minX, y: box.maxY - lineLength))

        return path
    }

    private func restartScanLineAnimation() {
        let distance = max(scanRect.height - 8, 0)
        guard distance > 0 else { return }
        scanLine.layer.removeAnimation(forKey: "scan")

        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = distance
        animation.duration = 1.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scanLine.layer.add(animation, forKey: "scan")
    }
}
