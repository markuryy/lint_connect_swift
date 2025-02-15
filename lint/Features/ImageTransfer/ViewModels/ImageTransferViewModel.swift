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
    @Published var isCropping = false
    @Published var cropRect: CGRect = .zero
    @Published var imageScale: CGFloat = 1.0
    @Published var imageOffset: CGSize = .zero
    
    // Default settings
    @Published var selectedResolution = CGSize(width: 240, height: 240) {  // Default to 240x240
        didSet {
            Task { @MainActor in
                if originalImage != nil {
                    updateProcessedImage()
                }
            }
        }
    }
    @Published var selectedColorSpace: ImageProcessor.ColorSpace = .rgb565 {  // Default to 16-bit
        didSet {
            Task { @MainActor in
                if originalImage != nil {
                    updateProcessedImage()
                }
            }
        }
    }
    @Published var rotationDegrees: CGFloat = 0 {
        didSet {
            Task { @MainActor in
                if originalImage != nil {
                    updateProcessedImage()
                }
            }
        }
    }
    
    // LVGL mode settings
    @Published var useLVGLMode: Bool = true {  // Default to LVGL mode
        didSet {
            if useLVGLMode {
                // Force 360x360 resolution in LVGL mode
                selectedResolution = CGSize(width: 360, height: 360)
            }
        }
    }
    
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
    @MainActor
    func handleImageSelection(_ image: UIImage) async {
        do {
            isProcessing = true
            // Clear current state
            processedImage = nil
            rotationDegrees = 0
            cropRect = .zero
            imageScale = 1.0
            imageOffset = .zero
            
            // Store original image with proper orientation
            if image.imageOrientation != .up {
                originalImage = image.normalizedImage()
            } else {
                originalImage = image
            }
            
            // Process the image immediately
            updateProcessedImage()
        } catch {
            errorMessage = "Failed to process image: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    func clearImage() {
        selectedItem = nil
        originalImage = nil
        processedImage = nil
        rotationDegrees = 0
        transferProgress = 0
        isProcessing = false
        isTransferring = false
        errorMessage = nil
        isCropping = false
        cropRect = .zero
        imageScale = 1.0
        imageOffset = .zero
    }
    
    func transferImage() {
        // Use the processed image for transfer
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
                
                if useLVGLMode {
                    // LVGL mode protocol
                    var startCmd: [UInt8] = [
                        0x03, // CMD_IMAGE_START
                        UInt8((Int(selectedResolution.width) >> 8) & 0xFF),
                        UInt8(Int(selectedResolution.width) & 0xFF),
                        UInt8((Int(selectedResolution.height) >> 8) & 0xFF),
                        UInt8(Int(selectedResolution.height) & 0xFF),
                        selectedColorSpace == .rgb888 ? 24 : 16,
                        UInt8((imageData.count >> 24) & 0xFF),
                        UInt8((imageData.count >> 16) & 0xFF),
                        UInt8((imageData.count >> 8) & 0xFF),
                        UInt8(imageData.count & 0xFF)
                    ]
                    
                    // Send START command
                    bleManager.sendData(Data(startCmd), withResponse: true)
                    
                    // Send image data in chunks
                    let chunkSize = 512 // BLE MTU size - 3 for ATT header
                    var offset = 0
                    
                    while offset < imageData.count {
                        let remainingBytes = imageData.count - offset
                        let currentChunkSize = min(chunkSize - 1, remainingBytes) // -1 for command byte
                        
                        var chunk: [UInt8] = [0x04] // CMD_IMAGE_DATA
                        let endIndex = offset + currentChunkSize
                        chunk.append(contentsOf: imageData[offset..<endIndex])
                        
                        bleManager.sendData(Data(chunk), withResponse: true)
                        offset += currentChunkSize
                        
                        // Update progress
                        transferProgress = Double(offset) / Double(imageData.count)
                    }
                } else {
                    // Original Bluefruit protocol
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
                    
                    // Send data with response
                    bleManager.sendData(data, withResponse: true)
                }
                
                isTransferring = false
                transferProgress = 1.0
            } catch {
                errorMessage = "Failed to transfer image: \(error.localizedDescription)"
                isTransferring = false
            }
        }
    }
    
    func finishCropping(croppedImage: UIImage) {
        originalImage = croppedImage
        isCropping = false
        updateProcessedImage()
    }
    
    // MARK: - Private Methods
    private func updateProcessedImage() {
        guard let image = originalImage else { return }
        isProcessing = true
        
        Task { @MainActor in
            // Always process from the original image to maintain quality
            if let processedUIImage = ImageProcessor.scaleAndRotateImage(
                image: image,
                resolution: selectedResolution,
                rotationDegrees: rotationDegrees,
                backgroundColor: .black
            ) {
                processedImage = processedUIImage
            }
            isProcessing = false
        }
    }
}
