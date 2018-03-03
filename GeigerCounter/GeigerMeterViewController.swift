//
//  GeigerMeterViewController.swift
//  GeigerCounter
//
//  Created by Pablo Caif on 10/2/18.
//  Copyright © 2018 Pablo Caif. All rights reserved.
//

import UIKit

class GeigerMeterViewController: UIViewController {

    @IBOutlet weak var meterView: MeterView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var battery: UILabel!
    @IBOutlet weak var standByButton: UIButton!
    @IBOutlet weak var switchOnButton: UIButton!
    
    var timer: Timer?
    let geigerMeterClient = GeigerMeterClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        standByButton.layer.borderWidth = 1.5
        standByButton.layer.borderColor = UIColor.white.cgColor
        standByButton.layer.cornerRadius = 7.0
        
        switchOnButton.layer.borderWidth = 1.5
        switchOnButton.layer.borderColor = UIColor.white.cgColor
        switchOnButton.layer.cornerRadius = 7.0
        
        geigerMeterClient.delegate = self
        geigerMeterClient.startReading()
        //This timer will pool for the battery level every 4 seconds
        timer = Timer(timeInterval: 4, repeats: true, block: requestBatteryRead)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        geigerMeterClient.stopReading()
        timer?.invalidate()
    }

    func requestBatteryRead(timer: Timer) {
        geigerMeterClient.readBatteryLevel()
    }
    
    
    @IBAction func didTapStandBy(_ sender: Any) {
        geigerMeterClient.execute(command: GeigerCommand.standBy)
    }
    
    @IBAction func didTapSwitchOn(_ sender: Any) {
        geigerMeterClient.execute(command: GeigerCommand.on)
    }
}

extension GeigerMeterViewController: GeigerClientDelegate {
    func clientDidUpdate(status: String) {
        self.status.text = status
    }
    
    func clientError(errorDescription: String) {
        let alertController = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func radiationReadingArrived(radiation: Float) {
        //We have received a new meter reading let's ask the view to draw it
        meterView.radiationIndicatorValue = radiation
    }
    
    func clientDidUpdate(batteryLevel: Int) {
        battery.text = "Battery: \(batteryLevel)%"
    }
    
    func clientExecutedCommand() {
        
    }
    
}

