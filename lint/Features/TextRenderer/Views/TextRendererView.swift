import SwiftUI

struct TextRendererView: View {
    @StateObject private var viewModel = TextRendererViewModel()
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        VStack(spacing: 24) {
            if !isEnabled {
                ContentUnavailableView {
                    Label("Device Required", systemImage: "antenna.radiowaves.left.and.right")
                } description: {
                    Text("Connect to a device to start sending text")
                }
                .frame(maxWidth: .infinity, minHeight: 240)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
                .contentPadding()
            } else {
                // Preview Area
                Group {
                    if viewModel.processedImage != nil {
                        Image(uiImage: viewModel.processedImage!)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            Color.black
                            Text(viewModel.text.isEmpty ? "Enter text below" : viewModel.text)
                                .font(.system(size: viewModel.fontSize, weight: viewModel.fontWeight))
                                .multilineTextAlignment(viewModel.alignment)
                                .foregroundStyle(viewModel.text.isEmpty ? .gray : .white)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .contentPadding()
                
                // Text Input and Controls
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Text Settings")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Text Input
                            TextField("Enter text", text: $viewModel.text, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            // Font Size
                            HStack {
                                Text("Size")
                                    .frame(width: 100, alignment: .leading)
                                
                                Slider(value: $viewModel.fontSize, in: 12...72) {
                                    Text("Font Size")
                                } minimumValueLabel: {
                                    Text("12")
                                } maximumValueLabel: {
                                    Text("72")
                                }
                            }
                            
                            // Font Weight
                            HStack {
                                Text("Weight")
                                    .frame(width: 100, alignment: .leading)
                                
                                Picker("", selection: $viewModel.fontWeight) {
                                    Text("Light").tag(Font.Weight.light)
                                    Text("Regular").tag(Font.Weight.regular)
                                    Text("Medium").tag(Font.Weight.medium)
                                    Text("Bold").tag(Font.Weight.bold)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Text Alignment
                            HStack {
                                Text("Alignment")
                                    .frame(width: 100, alignment: .leading)
                                
                                Picker("", selection: $viewModel.alignment) {
                                    Image(systemName: "text.alignleft").tag(TextAlignment.leading)
                                    Image(systemName: "text.aligncenter").tag(TextAlignment.center)
                                    Image(systemName: "text.alignright").tag(TextAlignment.trailing)
                                }
                                .pickerStyle(.segmented)
                            }
                            
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
                            }
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    }
                    .contentPadding()
                    
                    // Transfer Button or Progress
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
                        .contentPadding()
                    } else {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            viewModel.renderAndTransfer()
                        }) {
                            Label("Send Text", systemImage: "arrow.up.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.text.isEmpty)
                        .contentPadding()
                    }
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
    TextRendererView()
} 