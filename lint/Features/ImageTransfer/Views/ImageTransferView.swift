import SwiftUI
import UIKit
import PhotosUI

struct ImageTransferView: View {
    @StateObject private var viewModel = ImageTransferViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Preview with PhotosPicker
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
                            }
                            .aspectRatio(viewModel.selectedResolution.width / viewModel.selectedResolution.height, contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 400)
                        } else {
                            PhotosPicker(selection: $viewModel.selectedItem,
                                       matching: .images,
                                       photoLibrary: .shared()) {
                                ContentUnavailableView {
                                    Label("No Image Selected", systemImage: "photo")
                                } description: {
                                    Text("Tap here to select an image")
                                }
                                .frame(maxWidth: .infinity, minHeight: 240)
                            }
                            .onChange(of: viewModel.selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await viewModel.handleImageSelection(image)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    // Settings
                    VStack(spacing: 24) {
                        settingsView
                        transferControls
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Image Transfer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: $viewModel.selectedItem,
                               matching: .images,
                               photoLibrary: .shared()) {
                        Label("Select Image", systemImage: "photo.badge.plus")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
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
    
    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
            
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
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
    }
    
    private var transferControls: some View {
        VStack {
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
            } else {
                Button(action: viewModel.transferImage) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Transfer Image")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.processedImage == nil)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
    }
}

#Preview {
    ImageTransferView()
}
