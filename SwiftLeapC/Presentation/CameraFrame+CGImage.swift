//
//  CameraFrame+CGImage.swift
//  SwiftLeapC
//
//  Rendering helper (Presentation layer).
//

import CoreGraphics

extension CameraFrame {
    /// Creates a grayscale CGImage from an 8-bit, 1-channel image buffer.
    func makeCGImage() -> CGImage? {
        guard bytesPerPixel == 1 else { return nil } // expecting 8-bit gray
        guard width > 0, height > 0 else { return nil }
        guard data.count >= bytesPerRow * height else { return nil }

        guard let provider = CGDataProvider(data: data as CFData) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
