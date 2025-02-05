import SwiftUI
import CoreBluetooth

struct DevicesView: View {
    @StateObject private var viewModel = DevicesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Connection Status
                if viewModel.isScanning {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Scanning for devices...")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    }
                } else {
                    Text("Pull to refresh or tap Scan to search for devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Device List
                DeviceListView(viewModel: viewModel)
            }
            .padding()
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if viewModel.isScanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    } label: {
                        Label(viewModel.isScanning ? "Stop" : "Scan",
                              systemImage: viewModel.isScanning ? "stop.fill" : "magnifying.glass")
                    }
                    .tint(viewModel.isScanning ? .red : nil)
                }
            }
            .refreshable {
                viewModel.startScanning()
            }
        }
    }
}

#Preview {
    DevicesView()
}
