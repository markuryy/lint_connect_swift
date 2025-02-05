import SwiftUI
import CoreBluetooth

@MainActor
class DevicesViewModel: ObservableObject {
    // MARK: - Properties
    let bleManager = BLEManager.shared
    
    @AppStorage("hideUnnamedDevices") private var hideUnnamedDevices = true
    @AppStorage("maxDevicesToShow") private var maxDevicesToShow = 20
    @AppStorage("priorityKeywords") private var priorityKeywords = ""
    
    @Published private(set) var priorityDevices: [(peripheral: CBPeripheral, advertisementData: [String: Any])] = []
    @Published private(set) var otherDevices: [(peripheral: CBPeripheral, advertisementData: [String: Any])] = [] {
        didSet {
            print("🔵 Devices updated: \(priorityDevices.count + otherDevices.count) total")
            priorityDevices.forEach { device in
                print("🔵 Priority - \(deviceName(for: device.peripheral, advertisementData: device.advertisementData))")
            }
            otherDevices.forEach { device in
                print("🔵 Other - \(deviceName(for: device.peripheral, advertisementData: device.advertisementData))")
            }
        }
    }
    @Published private(set) var isScanning = false
    @Published private(set) var hasMoreDevices = false
    @Published private(set) var totalDeviceCount = 0
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
                    let keywords = priorityKeywords.split(separator: ",")
                        .map(String.init)
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    
                    let filteredDevices = hideUnnamedDevices ? 
                        discoveredDevices.filter { deviceName(for: $0.peripheral, advertisementData: $0.advertisementData) != "Unknown Device" } :
                        discoveredDevices
                    
                    // Filter into priority and other devices
                    let priorityDevices = filteredDevices.filter { device in
                        let name = deviceName(for: device.peripheral, advertisementData: device.advertisementData).lowercased()
                        return keywords.contains { keyword in
                            name.contains(keyword.lowercased())
                        }
                    }
                    
                    let otherDevices = filteredDevices.filter { device in
                        let name = deviceName(for: device.peripheral, advertisementData: device.advertisementData).lowercased()
                        return !keywords.contains { keyword in
                            name.contains(keyword.lowercased())
                        }
                    }
                    
                    totalDeviceCount = filteredDevices.count
                    let totalShown = min(maxDevicesToShow, filteredDevices.count)
                    hasMoreDevices = filteredDevices.count > totalShown
                    
                    // Show priority devices first, then fill remaining slots with other devices
                    self.priorityDevices = priorityDevices
                    let remainingSlots = max(0, totalShown - priorityDevices.count)
                    self.otherDevices = Array(otherDevices.prefix(remainingSlots))
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
    
    func loadMoreDevices() {
        maxDevicesToShow += 20
        // This will trigger the devices update through the discoveredPeripherals binding
    }
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
