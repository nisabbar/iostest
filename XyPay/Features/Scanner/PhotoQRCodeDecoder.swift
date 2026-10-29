import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

enum PhotoQRCodeDecoder {
    private enum DecodeError: LocalizedError {
        case unreadable, noQRCode

        var errorDescription: String? {
            switch self {
            case .unreadable: return AppText.photoReadFailed
            case .noQRCode: return AppText.photoNoQRCode
            }
        }
    }

    /// 文件读取、降采样和二维码识别均在后台处理，最终回调主线程。
    static func decode(_ provider: NSItemProvider,
                       completion: @escaping (Result<String, Error>) -> Void) {
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
            guard let url, error == nil else {
                DispatchQueue.main.async { completion(.failure(DecodeError.unreadable)) }
                return
            }

            // 系统会在此回调结束后删除源文件，先保存独立副本供后台任务读取。
            let localURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("qr-photo-\(UUID().uuidString)")
            do {
                try FileManager.default.copyItem(at: url, to: localURL)
            } catch {
                DispatchQueue.main.async { completion(.failure(DecodeError.unreadable)) }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                defer { try? FileManager.default.removeItem(at: localURL) }
                let result: Result<String, Error> = autoreleasepool {
                    do {
                        return .success(try decodeFile(localURL))
                    } catch let error as DecodeError {
                        return .failure(error)
                    } catch {
                        return .failure(DecodeError.unreadable)
                    }
                }
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    private static func decodeFile(_ url: URL) throws -> String {
        // 与 Android 一样限制长边为 2048，避免完整解码相机大图。
        guard let source = CGImageSourceCreateWithURL(url as CFURL,
                    [kCGImageSourceShouldCache: false] as CFDictionary),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 2048,
                  kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else {
            throw DecodeError.unreadable
        }

        // 透明 PNG 先合成白底，再尝试正常和反色二维码。
        let image = CIImage(cgImage: thumbnail)
        let white = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 1))
            .cropped(to: image.extent)
        let opaque = image.composited(over: white)
        let context = CIContext()
        for candidate in [opaque, opaque.applyingFilter("CIColorInvert")] {
            guard let bitmap = context.createCGImage(candidate, from: image.extent) else {
                throw DecodeError.unreadable
            }
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]
            let handler = VNImageRequestHandler(cgImage: bitmap, options: [:])
            try handler.perform([request])
            if let content = request.results?.compactMap({ $0.payloadStringValue }).first {
                return content
            }
        }
        throw DecodeError.noQRCode
    }
}
