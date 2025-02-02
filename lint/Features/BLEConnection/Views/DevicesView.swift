import SwiftUI
import CoreBluetooth

struct DevicesView: View {
    @StateObject private var viewModel = DevicesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.devices.isEmpty {
                    Section {
                        ForEach(viewModel.devices, id: \.peripheral.identifier) { device in
                            DeviceRow(
                                name: viewModel.deviceName(for: device.peripheral, advertisementData: device.advertisementData),
                                isUartAdvertised: viewModel.bleManager.isUartAdvertised(peripheral: device.peripheral, advertisementData: device.advertisementData),
                                isSelected: viewModel.selectedDevice?.identifier == device.peripheral.identifier,
                                connectionState: viewModel.connectionState,
                                onConnect: {
                                    viewModel.connect(to: device.peripheral)
                                },
                                onDisconnect: {
                                    viewModel.disconnect()
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text("Available Devices")
                            Spacer()
                            Text("\(viewModel.devices.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section {
                        if viewModel.isScanning {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Scanning for devices...")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ContentUnavailableView {
                                Label("No Devices Found", systemImage: "antenna.radiowaves.left.and.right.slash")
                            } description: {
                                Text("Tap Scan to search for nearby Bluetooth devices")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.isScanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    }) {
                        Label(viewModel.isScanning ? "Stop" : "Scan",
                              systemImage: viewModel.isScanning ? "stop.fill" : "arrow.clockwise")
                    }
                    .tint(viewModel.isScanning ? .red : nil)
                }
            }
        }
    }
}

struct DeviceRow: View {
    let name: String
    let isUartAdvertised: Bool
    let isSelected: Bool
    let connectionState: BLEManager.ConnectionState
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(isUartAdvertised ? .green : .orange)
                    Text(isUartAdvertised ? "UART Advertised" : "UART Compatible")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                switch connectionState {
                case .connected:
                    Button("Disconnect", role: .destructive, action: onDisconnect)
                        .buttonStyle(.bordered)
                case .connecting:
                    ProgressView()
                        .controlSize(.small)
                case .disconnecting:
                    ProgressView()
                        .controlSize(.small)
                case .disconnected:
                    Button("Connect", action: onConnect)
                        .buttonStyle(.bordered)
                }
            } else {
                Button("Connect", action: onConnect)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DevicesView()
}
