import PhotosUI
import SwiftUI

/// 系统单张照片选择器；取消时不触发识别或支付。
struct PhotoQRCodePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (NSItemProvider) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoQRCodePicker

        init(parent: PhotoQRCodePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let provider = results.first?.itemProvider {
                parent.onSelect(provider)
            }
            parent.dismiss()
        }
    }
}
