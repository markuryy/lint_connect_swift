import SwiftUI
import UIKit
import PhotosUI

struct ImageTransferView: View {
    @StateObject private var viewModel = ImageTransferViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 24) {
            if !Environment(\.isEnabled).wrappedValue {
                ContentUnavailableView {
                    Label("Device Required", systemImage: "antenna.radiowaves.left.and.right")
                } description: {
                    Text("Connect to a device to start transferring images")
                }
                .frame(maxWidth: .infinity, minHeight: 240)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
            } else if viewModel.processedImage == nil {
                // Step 1: Select Image
                PhotosPicker(selection: $viewModel.selectedItem,
                           matching: .images,
                           photoLibrary: .shared()) {
                    ContentUnavailableView {
                        Label("Select an Image", systemImage: "photo")
                    } description: {
                        Text("Tap here to choose an image to transfer")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 240)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
            } else {
                // Step 2: Configure and Transfer
                VStack(spacing: 24) {
                    // Image Preview
                    Group {
                        if viewModel.isProcessing {
                            ProgressView("Processing image...")
                                .frame(maxWidth: .infinity, minHeight: 240)
                        } else if let processedImage = viewModel.processedImage {
                            GeometryReader { geometry in
                                Image(uiImage: processedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .background(Color.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 5)
                                    .overlay(alignment: .topTrailing) {
                                        Button(role: .destructive) {
                                            viewModel.clearImage()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white, Color(.systemGray3))
                                                .symbolRenderingMode(.hierarchical)
                                        }
                                        .padding(8)
                                    }
                            }
                            .aspectRatio(viewModel.selectedResolution.width / viewModel.selectedResolution.height, contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 400)
                        }
                    }
                    .background(Color(.systemBackground))
                    
                // Settings and Controls
                VStack(spacing: 24) {
                    // Settings
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Image Settings")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                viewModel.clearImage()
                            } label: {
                                Label("Clear Image", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                            
                            VStack(spacing: 16) {
                                // Resolution Picker
                                HStack {
                                    Text("Resolution")
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Picker("", selection: $viewModel.selectedResolution) {
                                        ForEach(viewModel.availableResolutions, id: \.width) { size in
                                            Text("\(Int(size.width))×\(Int(size.height))")
                                                .tag(size)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Rotation Controls
                                HStack {
                                    Text("Rotation")
                                        .frame(width: 100, alignment: .leading)
                                    
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            viewModel.rotationDegrees = (viewModel.rotationDegrees - 90).truncatingRemainder(dividingBy: 360)
                                        }) {
                                            Image(systemName: "rotate.left")
                                                .font(.title2)
                                        }
                                        
                                        Button(action: {
                                            viewModel.rotationDegrees = (viewModel.rotationDegrees + 90).truncatingRemainder(dividingBy: 360)
                                        }) {
                                            Image(systemName: "rotate.right")
                                                .font(.title2)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Color Space Toggle
                                HStack {
                                    Text("Color Space")
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Picker("", selection: $viewModel.selectedColorSpace) {
                                        Text("16-bit").tag(ImageProcessor.ColorSpace.rgb565)
                                        Text("24-bit").tag(ImageProcessor.ColorSpace.rgb888)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        }
                        
                        // Transfer Button
                        if viewModel.isTransferring {
                            VStack(spacing: 12) {
                                ProgressView("Transferring...", value: viewModel.transferProgress)
                                    .progressViewStyle(.linear)
                                    .tint(.blue)
                                
                                Text("\(Int(viewModel.transferProgress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            }
                        } else {
                            Button(action: viewModel.transferImage) {
                                Label("Transfer Image", systemImage: "arrow.up.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.handleImageSelection(image)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    ImageTransferView()
}
