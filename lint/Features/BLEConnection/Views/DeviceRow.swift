import SwiftUI
import CoreBluetooth

struct DeviceRow: View {
    let name: String
    let isUartAdvertised: Bool
    let isSelected: Bool
    let connectionState: BLEManager.ConnectionState
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    // UART Status
                    Label {
                        Text(isUartAdvertised ? "UART Advertised" : "UART Compatible")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(isUartAdvertised ? .green : .orange)
                    }
                    .foregroundStyle(.secondary)
                    
                    // Connection Status (if selected)
                    if isSelected && connectionState != .disconnected {
                        Label {
                            switch connectionState {
                            case .connected:
                                Text("Connected")
                            case .connecting:
                                Text("Connecting...")
                            case .disconnecting:
                                Text("Disconnecting...")
                            case .disconnected:
                                EmptyView()
                            }
                        } icon: {
                            if connectionState == .connected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Connect/Disconnect Button
            if isSelected {
                switch connectionState {
                case .connected:
                    Button("Disconnect", role: .destructive, action: onDisconnect)
                        .buttonStyle(.bordered)
                case .connecting, .disconnecting:
                    EmptyView()
                case .disconnected:
                    Button("Connect", action: onConnect)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Button("Connect", action: onConnect)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        List {
            DeviceRow(
                name: "Test Device",
                isUartAdvertised: true,
                isSelected: true,
                connectionState: .connected,
                onConnect: {},
                onDisconnect: {}
            )
            
            DeviceRow(
                name: "Another Device",
                isUartAdvertised: false,
                isSelected: false,
                connectionState: .disconnected,
                onConnect: {},
                onDisconnect: {}
            )
            
            DeviceRow(
                name: "Connecting Device",
                isUartAdvertised: true,
                isSelected: true,
                connectionState: .connecting,
                onConnect: {},
                onDisconnect: {}
            )
        }
        .navigationTitle("Devices")
    }
}
