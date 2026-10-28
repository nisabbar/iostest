//
//  ScannerView.swift
//  XyPay
//
//  把 UIKit 的 QRScannerViewController 包成 SwiftUI 视图。
//

import SwiftUI

enum ScannerOutcome {
    case scanned(String)
    case cancelled
    case failure(String)
}

struct ScannerView: UIViewControllerRepresentable {

    let prompt: String
    let onOutcome: (ScannerOutcome) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController(prompt: prompt)
        controller.onScanned = { code in onOutcome(.scanned(code)) }
        controller.onCancel = { onOutcome(.cancelled) }
        controller.onFailure = { message in onOutcome(.failure(message)) }
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // 无需更新
    }
}
