import UIKit

enum ImageProcessorError: Error {
    case invalidImage
    case processingFailed
}

struct ImageProcessor {
    enum ColorSpace {
        case rgb565    // 16-bit (5-6-5)
        case rgb888    // 24-bit (8-8-8)
    }
    
    static func processImage(_ image: UIImage, targetSize: CGSize, colorSpace: ColorSpace, rotationDegrees: CGFloat) throws -> Data {
        guard let imagePixels32Bit = image.pixelData32bitRGB() else {
            throw ImageProcessorError.processingFailed
        }
        
        // Convert pixel data based on color space
        switch colorSpace {
        case .rgb565:
            // Convert 32bit color data to 16bit (565)
            var pixels = [UInt8]()
            pixels.reserveCapacity(imagePixels32Bit.count / 2)
            
            var i = 0
            while i < imagePixels32Bit.count {
                let r = imagePixels32Bit[i]
                let g = imagePixels32Bit[i + 1]
                let b = imagePixels32Bit[i + 2]
                // Skip alpha (i + 3)
                
                // Convert to RGB565 format (5 bits R, 6 bits G, 5 bits B)
                let rgb16 = (UInt16(r & 0xF8) << 8) | (UInt16(g & 0xFC) << 3) | UInt16(b >> 3)
                
                // Store in little-endian order (low byte first)
                pixels.append(UInt8(rgb16 & 0xFF))
                pixels.append(UInt8(rgb16 >> 8))
                
                i += 4  // Move to next pixel (RGBA)
            }
            return Data(pixels)
            
        case .rgb888:
            // Convert 32bit color data to 24bit (888)
            var pixels = [UInt8]()
            pixels.reserveCapacity((imagePixels32Bit.count / 4) * 3)
            
            var i = 0
            while i < imagePixels32Bit.count {
                pixels.append(imagePixels32Bit[i])     // R
                pixels.append(imagePixels32Bit[i + 1]) // G
                pixels.append(imagePixels32Bit[i + 2]) // B
                i += 4  // Skip alpha and move to next pixel
            }
            return Data(pixels)
        }
    }
    
    static func scaleAndRotateImage(image: UIImage, resolution: CGSize, rotationDegrees: CGFloat, backgroundColor: UIColor) -> UIImage? {
        // First normalize the image orientation
        let normalizedImage = image.normalizedImage()
        
        // Then apply manual rotation
        guard let rotatedImage = imageRotatedByDegrees(image: normalizedImage, rotationDegrees: rotationDegrees) else { return nil }
        
        // Calculate aspect-preserving dimensions
        let originalSize = rotatedImage.size
        let widthRatio = resolution.width / originalSize.width
        let heightRatio = resolution.height / originalSize.height
        let scale = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        // Create final image context with proper scale
        UIGraphicsBeginImageContextWithOptions(resolution, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill background
        backgroundColor.setFill()
        context.fill(CGRect(origin: .zero, size: resolution))
        
        // Calculate centered rect for the scaled image
        let x = (resolution.width - scaledSize.width) / 2
        let y = (resolution.height - scaledSize.height) / 2
        let centeredRect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
        
        // Draw the scaled image centered
        rotatedImage.draw(in: centeredRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private static func imageRotatedByDegrees(image: UIImage, rotationDegrees: CGFloat) -> UIImage? {
        // Normalize rotation to 0-360 degrees
        let normalizedDegrees = rotationDegrees.truncatingRemainder(dividingBy: 360)
        let radians = degreesToRadians(normalizedDegrees)
        
        // Calculate bounds after rotation
        let originalSize = image.size
        let bounds = CGRect(origin: .zero, size: originalSize)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let transform = CGAffineTransform(rotationAngle: radians)
        let rotatedBounds = bounds.applying(transform)
        
        // Create properly scaled context
        UIGraphicsBeginImageContextWithOptions(rotatedBounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext(),
              let cgImage = image.cgImage else { return nil }
        
        // Move to center, rotate, and scale
        context.translateBy(x: rotatedBounds.width / 2, y: rotatedBounds.height / 2)
        context.rotate(by: radians)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw the image
        let drawRect = CGRect(
            x: -originalSize.width / 2,
            y: -originalSize.height / 2,
            width: originalSize.width,
            height: originalSize.height
        )
        context.draw(cgImage, in: drawRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private static func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180
    }
}

extension UIImage {
    func normalizedImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    func pixelData32bitRGB() -> [UInt8]? {
        let bitsPerComponent = 8
        let size = self.size
        let dataSize = Int(size.width) * Int(size.height) * 4
        var pixelData = [UInt8](repeating: 0, count: dataSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                              width: Int(size.width),
                              height: Int(size.height),
                              bitsPerComponent: bitsPerComponent,
                              bytesPerRow: 4 * Int(size.width),
                              space: colorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)  // Use noneSkipLast to match Bluefruit's implementation
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return pixelData
    }
}

extension UInt16 {
    // Match Bluefruit's byte order handling
    var toBytes: [UInt8] {
        [UInt8(self & 0xFF), UInt8(self >> 8)]  // Little-endian order
    }
}
