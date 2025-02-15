import SwiftUI

@MainActor
class TextRendererViewModel: ObservableObject {
    // MARK: - Properties
    private let bleManager = BLEManager.shared
    
    @Published var text = ""
    @Published var fontSize: CGFloat = 32
    @Published var processedImage: UIImage?
    @Published var isTransferring = false
    @Published var transferProgress: Double = 0
    @Published var errorMessage: String?
    @Published var alignment: TextAlignment = .center
    @Published var fontWeight: Font.Weight = .regular
    
    // Default settings
    @Published var selectedResolution = CGSize(width: 240, height: 240)  // Default to 240x240
    @Published var selectedColorSpace: ImageProcessor.ColorSpace = .rgb565  // Default to 16-bit
    
    // Available resolutions (matching Bluefruit)
    let availableResolutions: [CGSize] = [
        CGSize(width: 64, height: 64),
        CGSize(width: 128, height: 128),
        CGSize(width: 240, height: 240),  // Default
        CGSize(width: 320, height: 320),
        CGSize(width: 360, height: 360),
        CGSize(width: 480, height: 480)
    ]
    
    // MARK: - Public Methods
    func renderAndTransfer() {
        guard !text.isEmpty else { return }
        
        let renderer = ImageRenderer(content:
            ZStack {
                Color.black
                Text(text)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .multilineTextAlignment(alignment)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: selectedResolution.width, height: selectedResolution.height)
            }
            .frame(width: selectedResolution.width, height: selectedResolution.height)
        )
        
        renderer.scale = 2.0 // Render at 2x for better quality
        
        if let uiImage = renderer.uiImage {
            processedImage = uiImage
            transferImage(uiImage)
        }
    }
    
    private func transferImage(_ image: UIImage) {
        Task {
            do {
                isTransferring = true
                transferProgress = 0
                
                let imageData = try ImageProcessor.processImage(
                    image,
                    targetSize: selectedResolution,
                    colorSpace: selectedColorSpace,
                    rotationDegrees: 0
                )
                
                // Prepare command packet (match Bluefruit's format)
                var command: [UInt8] = [0x21, 0x49] // !I
                command.append(selectedColorSpace == .rgb888 ? 24 : 16)  // Color space
                
                // Use little-endian byte order for width and height
                let width = UInt16(selectedResolution.width)
                let height = UInt16(selectedResolution.height)
                command.append(contentsOf: [UInt8(width & 0xFF), UInt8(width >> 8)])
                command.append(contentsOf: [UInt8(height & 0xFF), UInt8(height >> 8)])
                command.append(contentsOf: [UInt8](imageData))
                
                // Add CRC (match Bluefruit's exact CRC calculation)
                var data = Data(command)
                var crc: UInt8 = 0
                for byte in data {
                    crc = crc &+ byte
                }
                crc = ~crc  // One's complement
                data.append(crc)
                
                // Send data with response (match Bluefruit's packet handling)
                bleManager.sendData(data, withResponse: true)
                
                isTransferring = false
                transferProgress = 1.0
            } catch {
                errorMessage = "Failed to transfer image: \(error.localizedDescription)"
                isTransferring = false
            }
        }
    }
} 