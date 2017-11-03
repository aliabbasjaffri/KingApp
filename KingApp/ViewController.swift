//
//  ViewController.swift
//  KingApp
//
//  Created by Hadi on 11/10/2017.
//  Copyright © 2017 Hadi. All rights reserved.
//

import UIKit
import CoreBluetooth
import LocalAuthentication

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var bleDevice: CBPeripheral!
    var centralManager: CBCentralManager!
    var meowCharacteristic: CBCharacteristic!
    let authenticationContext = LAContext()
    var error:NSError?
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
            
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
            
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
            
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
            
        case .unknown:
            message = "The BLE state is unknown."
        case .poweredOn:
            message = "Bluetooth LE is turned on and ready for communication."
            print(message)
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFE0")], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        {
            if peripheralName == "HMSoft"
            {
                print("DISCOVERED Peripheral's name: \(peripheralName)")
                print("DISCOVERED Peripheral's UUID: \(peripheral.identifier.uuidString)")
                
                bleDevice = peripheral
                bleDevice.delegate = self
                centralManager.connect(bleDevice, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        authenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate",
                                             reply: { [unowned self] (success, error) -> Void in
                                                if( success )
                                                {
                                                    //Fingerprint recognized
                                                    self.bleDevice.discoverServices([CBUUID(string: "FFE0")])
                                                } else {
                                                    //If not recognized then
                                                    if let error = error {
                                                        print(error.localizedDescription)
                                                    }
                                                }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if error == nil
        {
            if let services = peripheral.services
            {
                for service in services
                {
                    if (service.uuid == CBUUID(string: "FFE0"))
                    {
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if error != nil
        {
            print("Error discovering characteristics!")
        }
        
        if (service.uuid == CBUUID(string: "FFE0"))
        {
            if let characteristics = service.characteristics
            {
                for characteristic in characteristics
                {
                    if characteristic.uuid == CBUUID(string: "FFE1")
                    {
                        self.meowCharacteristic = characteristic
                    }
                }
            }
        }
    }
    
    @IBAction func didSwitchToggle(_ sender: UISwitch)
    {
        if sender.isOn == true
        {
            if meowCharacteristic != nil
            {
                let message = "1"
                
                if let data = message.data(using: String.Encoding.utf8)
                {
                    bleDevice!.writeValue(data, for: meowCharacteristic!, type: .withoutResponse)
                }
            }
        }
        else
        {
            if meowCharacteristic != nil
            {
                let message = "2"
                
                if let data = message.data(using: String.Encoding.utf8)
                {
                    bleDevice!.writeValue(data, for: meowCharacteristic!, type: .withoutResponse)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        if error != nil{
            print("error in writing")
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        
        let isValidSensor : Bool = authenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        if isValidSensor {
            //Device have BiometricSensor
            //It Supports TouchID
        } else {
            //Device not support TouchID
            //For reason get error code from here
            print(error!.code)
            //print("Error", message: strMessage)
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
