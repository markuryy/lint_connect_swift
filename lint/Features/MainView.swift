import SwiftUI
import CoreBluetooth

struct MainView: View {
    @StateObject private var devicesViewModel = DevicesViewModel()
    @StateObject private var messageArrayViewModel = MessageArrayViewModel()
    @State private var selectedFunction: Function?
    @State private var showingSettings = false
    
    private let availableFunctions = [
        Function(
            name: "Message Array",
            icon: "text.bubble.fill",
            description: "Create and send multiple text messages with custom styling",
            type: .messageArray
        ),
        Function(
            name: "Image Transfer",
            icon: "photo.on.rectangle.angled",
            description: "Transfer images to your device with custom resolution and color settings",
            type: .imageTransfer
        ),
        Function(
            name: "Text Renderer",
            icon: "text.viewfinder",
            description: "Create and send text-based images with custom styling",
            type: .textRenderer
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let device = devicesViewModel.selectedDevice {
                    // Connected Device Status
                    connectedDeviceView(device)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    if let function = selectedFunction {
                        // Selected Function View
                        selectedFunctionView(function)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        // Function Selection
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Available Functions")
                                    .font(.title2.weight(.medium))
                                    .padding(.horizontal)
                                
                                FunctionList(
                                    functions: availableFunctions,
                                    isEnabled: devicesViewModel.connectionState == .connected,
                                    selectedFunction: selectedFunction,
                                    onSelect: { function in
                                        withAnimation {
                                            selectedFunction = function
                                        }
                                    }
                                )
                            }
                            .padding(.vertical)
                        }
                    }
                } else {
                    // No Device Connected - Show Device List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Bluetooth Devices")
                                .font(.title2.weight(.medium))
                                .padding(.horizontal)
                            
                            if devicesViewModel.isScanning {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Scanning for devices...")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            } else {
                                Text("Pull to refresh or tap Scan to search for devices")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                            
                            DeviceListView(viewModel: devicesViewModel)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("lint connect")
            .navigationBarTitleDisplayMode(.large)
            .toolbarRole(.browser)
            .toolbar {
                // Settings always visible
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                
                // Show scan button when no device connected
                if devicesViewModel.selectedDevice == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if devicesViewModel.isScanning {
                                devicesViewModel.stopScanning()
                            } else {
                                devicesViewModel.startScanning()
                            }
                        } label: {
                            Label(devicesViewModel.isScanning ? "Stop" : "Scan",
                                  systemImage: devicesViewModel.isScanning ? "stop.fill" : "magnifyingglass")
                        }
                        .tint(devicesViewModel.isScanning ? .red : nil)
                    }
                }
                
                // Back button when function selected
                if selectedFunction != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            withAnimation {
                                selectedFunction = nil
                            }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
            .refreshable {
                devicesViewModel.startScanning()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func connectedDeviceView(_ device: CBPeripheral) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connected to")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label {
                    Text(device.name ?? "Unknown Device")
                        .font(.headline)
                } icon: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                switch devicesViewModel.connectionState {
                case .connected:
                    Button("Disconnect", role: .destructive) {
                        withAnimation {
                            selectedFunction = nil
                            devicesViewModel.disconnect()
                        }
                    }
                    .buttonStyle(.bordered)
                case .connecting:
                    ProgressView()
                        .controlSize(.small)
                case .disconnecting:
                    ProgressView()
                        .controlSize(.small)
                case .disconnected:
                    EmptyView()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
        .padding()
    }
    
    @ViewBuilder
    private func selectedFunctionView(_ function: Function) -> some View {
        switch function.type {
        case .messageArray:
            MessageArrayView(viewModel: messageArrayViewModel)
        case .imageTransfer:
            ImageTransferView()
                .padding(.horizontal)
        case .textRenderer:
            TextRendererView()
                .padding(.horizontal)
        }
    }
}

#Preview {
    MainView()
}
