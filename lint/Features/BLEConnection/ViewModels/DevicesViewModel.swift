import SwiftUI
import CoreBluetooth

@MainActor
class DevicesViewModel: ObservableObject {
    // MARK: - Properties
    let bleManager = BLEManager.shared
    
    @Published private(set) var devices: [(peripheral: CBPeripheral, advertisementData: [String: Any])] = [] {
        didSet {
            print("🔵 Devices updated: \(devices.count) total")
            devices.forEach { device in
                print("🔵 - \(deviceName(for: device.peripheral, advertisementData: device.advertisementData))")
            }
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var connectionState: BLEManager.ConnectionState = .disconnected
    @Published private(set) var selectedDevice: CBPeripheral?
    
    // MARK: - Initialization
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe BLEManager's published properties
        Task {
            for await isScanning in bleManager.$isScanning.values {
                await MainActor.run {
                    self.isScanning = isScanning
                    if isScanning {
                        print("🔵 Started scanning")
                    } else {
                        print("🔵 Stopped scanning")
                    }
                }
            }
        }
        
        Task {
            for await discoveredDevices in bleManager.$discoveredPeripherals.values {
                await MainActor.run {
                    // Show all devices initially
                    self.devices = discoveredDevices
                }
            }
        }
        
        Task {
            for await state in bleManager.$connectionState.values {
                await MainActor.run {
                    self.connectionState = state
                    print("🔵 Connection state changed: \(state)")
                }
            }
        }
        
        Task {
            for await peripheral in bleManager.$connectedPeripheral.values {
                await MainActor.run {
                    self.selectedDevice = peripheral
                    if let peripheral = peripheral {
                        print("🔵 Selected device: \(peripheral.name ?? peripheral.identifier.uuidString)")
                    } else {
                        print("🔵 No device selected")
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func startScanning() {
        bleManager.startScanning()
    }
    
    func stopScanning() {
        bleManager.stopScanning()
    }
    
    func connect(to peripheral: CBPeripheral) {
        bleManager.connect(to: peripheral)
    }
    
    func disconnect() {
        bleManager.disconnect()
    }
    
    // MARK: - Helper Methods
    func deviceName(for peripheral: CBPeripheral, advertisementData: [String: Any]) -> String {
        // First try to get name from advertisement data
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            return localName
        }
        // Fall back to peripheral name
        return peripheral.name ?? "Unknown Device"
    }
    
    func connectionStateText(for state: BLEManager.ConnectionState) -> String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        }
    }
}
