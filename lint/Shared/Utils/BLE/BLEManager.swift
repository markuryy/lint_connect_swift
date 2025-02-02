import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    // MARK: - Properties
    static let shared = BLEManager()
    
    @Published var isScanning = false
    @Published var discoveredPeripherals: [(peripheral: CBPeripheral, advertisementData: [String: Any])] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var connectionState: ConnectionState = .disconnected
    
    private var centralManager: CBCentralManager!
    private var uartService: CBService?
    private var rxCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    
    // MARK: - Constants
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
    
    private let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // MARK: - Initialization
    // Constants
    private static let kAlwaysAllowDuplicateKeys = true
    private static let kUndefinedRssiValue = 127
    
    private override init() {
        super.init()
        print("🔵 Initializing BLEManager")
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.global(qos: .background),
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }
    
    // MARK: - Public Methods
    func startScanning() {
        print("🔵 Start scanning requested")
        guard centralManager.state == .poweredOn else {
            print("🔵 Cannot start scanning - Bluetooth not powered on (current state: \(centralManager.state.rawValue))")
            return
        }
        
        // Clear previous results
        discoveredPeripherals.removeAll()
        
        // First try to find already connected devices
        print("🔵 Looking for connected peripherals")
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [uartServiceUUID])
        for peripheral in connectedPeripherals {
            print("🔵 Found connected peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
            peripheral.delegate = self
            let advertisementData: [String: Any] = [
                CBAdvertisementDataServiceUUIDsKey: [uartServiceUUID],
                CBAdvertisementDataLocalNameKey: peripheral.name ?? "Unknown Device"
            ]
            DispatchQueue.main.async {
                self.discoveredPeripherals.append((peripheral: peripheral, advertisementData: advertisementData))
            }
        }
        
        // Then start scanning for new devices
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        print("🔵 Starting scan with options: \(options)")
        // First try scanning for UART service
        centralManager.scanForPeripherals(withServices: [uartServiceUUID], options: options)
        
        // After a short delay, scan for all devices if no UART devices found
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if self.discoveredPeripherals.isEmpty {
                print("🔵 No UART devices found, scanning for all devices")
                self.centralManager.stopScan()
                self.centralManager.scanForPeripherals(withServices: nil, options: options)
            }
        }
        isScanning = true
    }
    
    func stopScanning() {
        print("🔵 Stopping scan")
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        connectionState = .disconnecting
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func sendData(_ data: Data, withResponse: Bool = true) {
        guard let peripheral = connectedPeripheral,
              let rxCharacteristic = rxCharacteristic,
              connectionState == .connected else { return }
        
        // Split data into chunks that fit within MTU size
        let mtu = peripheral.maximumWriteValueLength(for: withResponse ? .withResponse : .withoutResponse)
        var offset = 0
        
        print("🔵 Sending data with size: \(data.count) bytes")
        print("🔵 MTU size: \(mtu) bytes")
        print("🔵 Using write type: \(withResponse ? "withResponse" : "withoutResponse")")
        
        while offset < data.count {
            let chunkSize = min(data.count - offset, mtu)
            let chunk = data.subdata(in: offset..<(offset + chunkSize))
            
            print("🔵 Sending chunk at offset \(offset), size: \(chunkSize)")
            peripheral.writeValue(chunk, for: rxCharacteristic, type: withResponse ? .withResponse : .withoutResponse)
            
            offset += chunkSize
        }
        
        print("🔵 Finished sending data")
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("🔵 Bluetooth state changed: \(central.state.rawValue)")
        
        switch central.state {
        case .poweredOn:
            print("🔵 Bluetooth is powered on and ready")
            // If we were trying to scan before, start now
            if isScanning {
                startScanning()
            }
        case .poweredOff:
            print("🔵 Bluetooth is powered off")
            stopScanning()
        case .resetting:
            print("🔵 Bluetooth is resetting")
            stopScanning()
        case .unauthorized:
            print("🔵 Bluetooth is unauthorized")
            stopScanning()
        case .unsupported:
            print("🔵 Bluetooth is not supported")
            stopScanning()
        case .unknown:
            print("🔵 Bluetooth state is unknown")
            stopScanning()
        @unknown default:
            print("🔵 Bluetooth state is unknown (future state)")
            stopScanning()
        }
        
        // Post state update notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didUpdateBleState, object: nil)
        }
    }
    
    // MARK: - UART Service Methods
    func isUartAdvertised(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            return services.contains(uartServiceUUID)
        }
        return false
    }
    
    func hasUart(peripheral: CBPeripheral) -> Bool {
        return peripheral.services?.contains(where: { $0.uuid == uartServiceUUID }) ?? false
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("🔵 Discovered device: \(peripheral.name ?? peripheral.identifier.uuidString)")
        print("🔵 Advertisement data: \(advertisementData)")
        print("🔵 RSSI: \(RSSI)")
        
        // Always add the device, even with undefined RSSI
        DispatchQueue.main.async {
            // Check if device is already discovered
            if let existingIndex = self.discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                print("🔵 Updating existing device")
                // Update existing device
                self.discoveredPeripherals[existingIndex] = (peripheral: peripheral, advertisementData: advertisementData)
            } else {
                print("🔵 Adding new device")
                // Add new device
                self.discoveredPeripherals.append((peripheral: peripheral, advertisementData: advertisementData))
            }
            
            // Post notification for UI update
            NotificationCenter.default.post(name: .didDiscoverPeripheral, object: nil, userInfo: ["peripheral": peripheral])
        }
        
        // Only try to connect if we're not already connected to a device
        if connectedPeripheral == nil {
            // If device advertises UART service, try to connect
            if self.isUartAdvertised(peripheral: peripheral, advertisementData: advertisementData) {
                print("🔵 Found device advertising UART service")
                if peripheral.state == .disconnected {
                    print("🔵 Attempting to connect to UART device")
                    self.connect(to: peripheral)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🔵 Connected to device: \(peripheral.name ?? peripheral.identifier.uuidString)")
        
        // Stop scanning immediately after successful connection
        if isScanning {
            print("🔵 Stopping scan after successful connection")
            stopScanning()
        }
        
        // Update state after stopping scan to ensure proper UI update order
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            self.connectionState = .connected
            
            // Post connection notification
            NotificationCenter.default.post(
                name: .didConnectToPeripheral,
                object: nil,
                userInfo: ["peripheral": peripheral]
            )
        }
        
        peripheral.delegate = self
        peripheral.discoverServices([uartServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔵 Disconnected from device: \(peripheral.name ?? peripheral.identifier.uuidString)")
        if let error = error {
            print("🔵 Disconnect error: \(error.localizedDescription)")
        }
        
        if peripheral == connectedPeripheral {
            DispatchQueue.main.async {
                self.connectedPeripheral = nil
                self.connectionState = .disconnected
                self.uartService = nil
                self.rxCharacteristic = nil
                self.txCharacteristic = nil
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("🔵 Failed to connect to device: \(peripheral.name ?? peripheral.identifier.uuidString)")
        if let error = error {
            print("🔵 Connection error: \(error.localizedDescription)")
        }
        
        if peripheral == connectedPeripheral {
            DispatchQueue.main.async {
                self.connectedPeripheral = nil
                self.connectionState = .disconnected
            }
        }
    }
}

// MARK: - Custom Notifications
extension Notification.Name {
    static let didDiscoverPeripheral = Notification.Name("com.lint.ble.didDiscoverPeripheral")
    static let didConnectToPeripheral = Notification.Name("com.lint.ble.didConnectToPeripheral")
    static let didDisconnectFromPeripheral = Notification.Name("com.lint.ble.didDisconnectFromPeripheral")
    static let didUpdateBleState = Notification.Name("com.lint.ble.didUpdateBleState")
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("🔵 Discovered services for device: \(peripheral.name ?? peripheral.identifier.uuidString)")
        if let error = error {
            print("🔵 Service discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        print("🔵 Services: \(services.map { $0.uuid.uuidString })")
        
        for service in services {
            if service.uuid == uartServiceUUID {
                print("🔵 Found UART service")
                uartService = service
                peripheral.discoverCharacteristics([rxCharacteristicUUID, txCharacteristicUUID], for: service)
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("🔵 Discovered characteristics for service: \(service.uuid.uuidString)")
        if let error = error {
            print("🔵 Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        print("🔵 Characteristics: \(characteristics.map { $0.uuid.uuidString })")
        
        for characteristic in characteristics {
            if characteristic.uuid == rxCharacteristicUUID {
                print("🔵 Found RX characteristic")
                rxCharacteristic = characteristic
            }
            else if characteristic.uuid == txCharacteristicUUID {
                print("🔵 Found TX characteristic")
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == txCharacteristic,
              let data = characteristic.value else { return }
        
        print("🔵 Received data from TX characteristic: \(data)")
    }
}
