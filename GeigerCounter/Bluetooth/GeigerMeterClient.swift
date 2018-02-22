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
    func cliendDidUpdate(batteryLevel: Float)
}

public class GeigerMeterClient: NSObject {
    
    private let serviceScanParametersID = "1813"
    private let analogCharID = "2A58"
    
    private var blueCentralMgr :CBCentralManager?
    private var geigerMeterPeripheral: CBPeripheral?
    private var radiationReadingCharacteristic: CBCharacteristic?
    private var shouldBeConnected = false
    
    public weak var delegate: GeigerClientDelegate?
    
    private func scanForGeigerReader() {
        if blueCentralMgr == nil {
            blueCentralMgr = CBCentralManager(delegate: self, queue: nil)
        }
        if blueCentralMgr?.state == .poweredOn {
            blueCentralMgr?.scanForPeripherals(withServices: [CBUUID(string: serviceScanParametersID)], options: nil)
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
}

// MARK: CBCentralManagerDelegate
extension GeigerMeterClient: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            blueCentralMgr?.scanForPeripherals(withServices: [CBUUID(string: serviceScanParametersID)], options: nil)
            print("Hardware powered on")
        case .poweredOff:
            print("Hardware powered off")
        case .resetting:
            blueCentralMgr?.stopScan()
            print("Hardware reseting")
        case .unauthorized:
            print("Hardware unauthorised")
        case .unsupported:
            print("Hardware unsoported")
        case .unknown:
            print("Hardware unknown")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Name \(advertisementData[CBAdvertisementDataLocalNameKey] ?? "Unknown") Peripheral name=\(peripheral.name ?? "") ID=\(peripheral.identifier.uuidString)\n")
        if peripheral.name != nil {
            print("Advertisement data \(advertisementData)")
            print("Peripheral \(peripheral.debugDescription) \n")
            central.stopScan()
            geigerMeterPeripheral = peripheral
            geigerMeterPeripheral!.delegate = self
            central.connect(geigerMeterPeripheral!, options: nil)
            
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.debugDescription)")
        delegate?.clientDidUpdate(status: "Connected to \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.discoverServices([CBUUID(string: serviceScanParametersID)])
        peripheral.delegate = self
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let error = error else {return}
        print("Peripheral fail to connect \(peripheral.debugDescription) error=\(error.localizedDescription)")
        delegate?.clientError(errorDescription: error.localizedDescription)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if shouldBeConnected {
            print("Server disconnected reconnecting....")
            scanForGeigerReader()
        }
    }
}

// MARK: CBPeripheralDelegate
extension GeigerMeterClient: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach({ (service) in
            print("Service \(service.description) ID=\(service.uuid.uuidString)")
            peripheral.discoverCharacteristics([CBUUID(string: analogCharID)], for: service)
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach({ (charact) in
            print("Characteristic \(charact.uuid.uuidString) for service \(service.description) pheriferal \(peripheral.description)")
            geigerMeterPeripheral?.discoverDescriptors(for: charact)
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        characteristic.descriptors?.forEach({ (descriptor) in
            print("Descriptor \(descriptor.debugDescription) Characteristic \(characteristic.uuid.uuidString)")
            geigerMeterPeripheral?.readValue(for: descriptor)
        })
        radiationReadingCharacteristic = characteristic
        geigerMeterPeripheral?.setNotifyValue(true, for: characteristic)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let valueData = characteristic.value else {
            return
        }
        
        let readingSize = MemoryLayout<Float32>.size
        let number = UnsafeMutablePointer<Float32>.allocate(capacity: 1)
        number.initialize(to: 0.0)
        defer {
            number.deallocate(capacity: 1)
        }
        let byesCopied = valueData.copyBytes(to: UnsafeMutableBufferPointer(start: number, count: 1), from: 0 ..< valueData.startIndex + readingSize)
        guard byesCopied == readingSize else {return}
        delegate?.radiationReadingArrived(radiation: Float(number.pointee))
    }
}
