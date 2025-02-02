import SwiftUI
import PhotosUI

@MainActor
class ImageTransferViewModel: ObservableObject {
    // MARK: - Properties
    private let bleManager = BLEManager.shared
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var originalImage: UIImage?
    @Published var processedImage: UIImage?  // Store the processed UIImage for both preview and transfer
    @Published var isProcessing = false
    @Published var isTransferring = false
    @Published var transferProgress: Double = 0
    @Published var errorMessage: String?
    
    // Default settings
    @Published var selectedResolution = CGSize(width: 240, height: 240) {  // Default to 240x240
        didSet {
            updateProcessedImage()
        }
    }
    @Published var selectedColorSpace: ImageProcessor.ColorSpace = .rgb565 {  // Default to 16-bit
        didSet {
            updateProcessedImage()
        }
    }
    @Published var rotationDegrees: CGFloat = 0 {
        didSet {
            updateProcessedImage()
        }
    }
    
    // Available resolutions (matching Bluefruit)
    let availableResolutions: [CGSize] = [
        CGSize(width: 64, height: 64),
        CGSize(width: 128, height: 128),
        CGSize(width: 240, height: 240),  // Default
        CGSize(width: 320, height: 320),
        CGSize(width: 480, height: 480)
    ]
    
    // MARK: - Public Methods
    @MainActor
    func handleImageSelection(_ image: UIImage) async {
        do {
            isProcessing = true
            originalImage = image
            rotationDegrees = 0  // Reset rotation when new image selected
            updateProcessedImage()
        } catch {
            errorMessage = "Failed to process image: \(error.localizedDescription)"
        }
        isProcessing = false
    }
    
    func transferImage() {
        // Use the processed image for transfer, just like Bluefruit
        guard let processedImage = processedImage else { return }
        
        Task {
            do {
                isTransferring = true
                transferProgress = 0
                
                // Use the processed image directly for transfer since it's already rotated and scaled
                let imageData = try ImageProcessor.processImage(
                    processedImage,
                    targetSize: processedImage.size, // Use actual size of processed image
                    colorSpace: selectedColorSpace,
                    rotationDegrees: 0 // Image is already rotated
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
    
    // MARK: - Private Methods
    private func updateProcessedImage() {
        guard let image = originalImage else { return }
        
        // Process image using exact Bluefruit scaling
        if let processedUIImage = ImageProcessor.scaleAndRotateImage(
            image: image,
            resolution: selectedResolution,
            rotationDegrees: rotationDegrees,
            backgroundColor: .black
        ) {
            processedImage = processedUIImage
        }
    }
}
