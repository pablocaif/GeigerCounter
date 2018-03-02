//
//  GeigerMeterClient.swift
//  GeigerCounter
//
//  Created by Pablo Caif on 17/2/18.
//  Copyright © 2018 Pablo Caif. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol GeigerClientDelegate: NSObjectProtocol {
    func clientDidUpdate(status: String)
    func clientError(errorDescription: String)
    func radiationReadingArrived(radiation: Float)
    func clientDidUpdate(batteryLevel: Int)
    func clientExecutedCommand()
}

public class GeigerMeterClient: NSObject {

    private let peripheralIDKey = "PeripheralIDKey"
    private let serviceGeigerCounterID = CBUUID(string: "9822918C-312C-48FA-AD7C-A5E9853C5AC5")
    private let radiationCountCharID = CBUUID(string: "190124D9-BB53-4ACB-9C48-F4D5F8C81668")

    private let geigerBatteryServiceID = CBUUID(string: "FA0EA16D-49D5-438C-99A7-CF61ACA41F36")
    private let geigerBatteryLevelCharID = CBUUID(string: "FA0EA16D-49D5-438C-99A7-CF61ACA41F36")
    private let geigerCommandCharID = CBUUID(string: "F35065D4-DE1D-4A50-B7D0-4AE378B7E51D")
    
    private var blueCentralMgr :CBCentralManager?
    private var geigerMeterPeripheral: CBPeripheral?
    private var radiationReadingCharacteristic: CBCharacteristic?
    private var geigerBatteryCharacteristic: CBCharacteristic?
    private var geigerCommandCharacteristic: CBCharacteristic?
    private var shouldBeConnected = false
    
    private var reconnectionState: ReconnectionStep?
    
    public weak var delegate: GeigerClientDelegate?
    
    private func scanForGeigerReader() {
        if blueCentralMgr == nil {
            blueCentralMgr = CBCentralManager(delegate: self, queue: nil)
        }
        if blueCentralMgr?.state == .poweredOn {
            attemptReconnectionForSavedPeripheral()
        }
    }

    public func startReading() {
        shouldBeConnected = true
        scanForGeigerReader()
    }

    public func stopReading() {
        shouldBeConnected = false
        if radiationReadingCharacteristic != nil {
            geigerMeterPeripheral?.setNotifyValue(false, for: radiationReadingCharacteristic!)
        }
        if geigerMeterPeripheral != nil {
            blueCentralMgr?.cancelPeripheralConnection(geigerMeterPeripheral!)
        }
    }
    
    public func readBatteryLevel() {
        guard let peripheral = geigerMeterPeripheral, let batteryChar = geigerBatteryCharacteristic else {return}
        peripheral.readValue(for: batteryChar)
    }
    
    public func execute(command: GeigerCommand) {
        guard let peripheral = geigerMeterPeripheral, let commandChar = geigerCommandCharacteristic else {return}
        var commandCode = command.rawValue
        peripheral.writeValue(Data(bytes: &commandCode, count: MemoryLayout<UInt8>.size), for: commandChar, type: .withResponse)
    }
}

// MARK: Reconnection logic
extension GeigerMeterClient {
    private func attemptReconnectionForSavedPeripheral() {
        if
            let peripheralID = UserDefaults.standard.string(forKey: peripheralIDKey),
            let peripheralUUID = UUID(uuidString: peripheralID) {
            connectToKnownPeripheral(uuid: peripheralUUID)
        } else {
            scanForPeripheral()
        }
    }
    
    private func connectToKnownPeripheral(uuid: UUID) {
        guard let centralManager = blueCentralMgr else {return}
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if !peripherals.isEmpty && reconnectionState != ReconnectionStep.connectingToSavedPeripheral {
            geigerMeterPeripheral = peripherals[0]
            reconnectionState = ReconnectionStep.connectingToSavedPeripheral
            centralManager.connect(geigerMeterPeripheral!, options: nil)
        } else {
            let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID(nsuuid: uuid)])
            if !connectedPeripherals.isEmpty {
                geigerMeterPeripheral = connectedPeripherals[0]
                reconnectionState = ReconnectionStep.connectingToSystemConnectedPeripgeral
                centralManager.connect(geigerMeterPeripheral!, options: nil)
            } else {
                scanForPeripheral()
            }
        }
        
    }
    
    private func scanForPeripheral() {
        blueCentralMgr?.scanForPeripherals(withServices: [serviceGeigerCounterID, geigerBatteryServiceID], options: nil)
    }
}

// MARK: CBCentralManagerDelegate
extension GeigerMeterClient: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            attemptReconnectionForSavedPeripheral()
            print("Hardware powered on")
        case .poweredOff:
            print("Hardware powered off")
        case .resetting:
            blueCentralMgr?.stopScan()
            print("Hardware reseting")
        case .unauthorized:
            let message = "Hardware unauthorized"
            print(message)
            delegate?.clientError(errorDescription: message)
        case .unsupported:
            let message = "Hardware unsupported"
            print(message)
            delegate?.clientError(errorDescription: message)
        case .unknown:
            let message = "Hardware unknown"
            print(message)
            delegate?.clientError(errorDescription: message)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Name \(advertisementData[CBAdvertisementDataLocalNameKey] ?? "Unknown") Peripheral name=\(peripheral.name ?? "") ID=\(peripheral.identifier.uuidString)\n")
        print("Advertisement data \(advertisementData)")
        print("Peripheral \(peripheral.debugDescription) \n")
        central.stopScan()
        geigerMeterPeripheral = peripheral
        geigerMeterPeripheral!.delegate = self
        central.connect(geigerMeterPeripheral!, options: nil)
        reconnectionState = ReconnectionStep.connectingToDiscoveredPeripheral
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.debugDescription)")
        delegate?.clientDidUpdate(status: "Connected to \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.discoverServices([serviceGeigerCounterID, geigerBatteryServiceID])
        peripheral.delegate = self
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: peripheralIDKey)
        reconnectionState = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let error = error else {return}
        print("Peripheral fail to connect \(peripheral.debugDescription) error=\(error.localizedDescription)")
        if reconnectionState == ReconnectionStep.connectingToSavedPeripheral {
            attemptReconnectionForSavedPeripheral()
        } else {
            scanForPeripheral()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if shouldBeConnected {
            print("Server disconnected reconnecting....")
            scanForGeigerReader()
        }
        delegate?.clientDidUpdate(status: "Disconnected")
    }
}

// MARK: CBPeripheralDelegate
extension GeigerMeterClient: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach({ (service) in
            print("Service \(service.description) ID=\(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach({ (characteristic) in
            print("Characteristic \(characteristic.uuid.uuidString) for service \(service.description) pheriferal \(peripheral.description)")
            geigerMeterPeripheral?.discoverDescriptors(for: characteristic)
            switch characteristic.uuid {
            case radiationCountCharID:
                radiationReadingCharacteristic = characteristic
                geigerMeterPeripheral?.setNotifyValue(true, for: characteristic)
            case geigerBatteryLevelCharID:
                geigerBatteryCharacteristic = characteristic
            case geigerCommandCharID:
                geigerCommandCharacteristic = characteristic
            default:
                print("Unexpected characteristic")
            }
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        characteristic.descriptors?.forEach({ (descriptor) in
            print("Descriptor \(descriptor.debugDescription) Characteristic \(characteristic.uuid.uuidString)")
            geigerMeterPeripheral?.readValue(for: descriptor)
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("Characteristic=\(descriptor.characteristic.uuid.uuidString), descriptor value=\(String(describing: descriptor.value))")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == geigerCommandCharID {
            if let error = error {
                delegate?.clientError(errorDescription: error.localizedDescription)
            } else {
                delegate?.clientExecutedCommand()
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let valueData = characteristic.value else {
            return
        }
        
        if characteristic.uuid == radiationCountCharID {
           readRadiation(data: valueData)
        } else if characteristic.uuid == geigerBatteryLevelCharID {
            var batteryLevel = UInt8(0)
            valueData.copyBytes(to: &batteryLevel, count: MemoryLayout<UInt8>.size)
            delegate?.clientDidUpdate(batteryLevel: Int(batteryLevel))
        }
    }
    
    func readRadiation(data: Data) {
        let readingSize = MemoryLayout<Float32>.size
        let number = UnsafeMutablePointer<Float32>.allocate(capacity: 1)
        number.initialize(to: 0.0)
        defer {
            number.deallocate(capacity: 1)
        }
        let byesCopied = data.copyBytes(to: UnsafeMutableBufferPointer(start: number, count: 1), from: 0 ..< data.startIndex + readingSize)
        guard byesCopied == readingSize else {return}
        delegate?.radiationReadingArrived(radiation: Float(number.pointee))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        invalidatedServices.forEach { (service) in
            if geigerCommandCharacteristic?.service.uuid == service.uuid {
                geigerCommandCharacteristic = nil
                radiationReadingCharacteristic = nil
                delegate?.clientDidUpdate(status: "Disconnected")
            }
            
            if geigerBatteryCharacteristic?.service.uuid == service.uuid {
                geigerBatteryCharacteristic = nil
                delegate?.clientDidUpdate(status: "Disconnected")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("char=\(characteristic.uuid.uuidString) error=\(String(describing: error?.localizedDescription))")
    }
}

enum ReconnectionStep {
    case connectingToSavedPeripheral
    case connectingToSystemConnectedPeripgeral
    case connectingToDiscoveredPeripheral
}

public enum GeigerCommand: UInt8 {
    case standBy = 0
    case on
}
