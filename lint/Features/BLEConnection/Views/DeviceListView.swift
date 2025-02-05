import SwiftUI
import CoreBluetooth

struct DeviceListView: View {
    @ObservedObject var viewModel: DevicesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.priorityDevices.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        ForEach(viewModel.priorityDevices, id: \.peripheral.identifier) { device in
                            DeviceRow(
                                name: viewModel.deviceName(for: device.peripheral, advertisementData: device.advertisementData),
                                isUartAdvertised: viewModel.bleManager.isUartAdvertised(peripheral: device.peripheral, advertisementData: device.advertisementData),
                                isSelected: viewModel.selectedDevice?.identifier == device.peripheral.identifier,
                                connectionState: viewModel.connectionState,
                                onConnect: {
                                    viewModel.connect(to: device.peripheral)
                                    dismiss()
                                },
                                onDisconnect: {
                                    viewModel.disconnect()
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            if device.peripheral.identifier != viewModel.priorityDevices.last?.peripheral.identifier {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } header: {
                    HStack {
                        Text("Priority Devices")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.priorityDevices.count)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            
            if !viewModel.otherDevices.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        ForEach(viewModel.otherDevices, id: \.peripheral.identifier) { device in
                            DeviceRow(
                                name: viewModel.deviceName(for: device.peripheral, advertisementData: device.advertisementData),
                                isUartAdvertised: viewModel.bleManager.isUartAdvertised(peripheral: device.peripheral, advertisementData: device.advertisementData),
                                isSelected: viewModel.selectedDevice?.identifier == device.peripheral.identifier,
                                connectionState: viewModel.connectionState,
                                onConnect: {
                                    viewModel.connect(to: device.peripheral)
                                    dismiss()
                                },
                                onDisconnect: {
                                    viewModel.disconnect()
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            if device.peripheral.identifier != viewModel.otherDevices.last?.peripheral.identifier {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } header: {
                    HStack {
                        Text("Other Devices")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.otherDevices.count)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            
            if viewModel.priorityDevices.isEmpty && viewModel.otherDevices.isEmpty && !viewModel.isScanning {
                ContentUnavailableView {
                    Label("No Devices Found", systemImage: "antenna.radiowaves.left.and.right.slash")
                } description: {
                    Text("Pull down to scan for nearby Bluetooth devices")
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
            }
            
            if viewModel.hasMoreDevices {
                Button {
                    viewModel.loadMoreDevices()
                } label: {
                    HStack {
                        Text("Load More")
                        Text("(\(viewModel.totalDeviceCount - (viewModel.priorityDevices.count + viewModel.otherDevices.count)) remaining)")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
        }
    }
}

#Preview {
    DeviceListView(viewModel: DevicesViewModel())
        .padding()
}
