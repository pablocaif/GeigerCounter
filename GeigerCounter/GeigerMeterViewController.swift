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
    
    var timer: Timer?
    let geigerMeterClient = GeigerMeterClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        geigerMeterClient.delegate = self
        geigerMeterClient.startReading()
        timer = Timer(timeInterval: 4, repeats: true, block: requestBatteryRead)
        //RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateValue(timer: Timer?) {
        let value = Float(arc4random() % 100)
        meterView.radiationIndicatorValue = value
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        geigerMeterClient.stopReading()
        timer?.invalidate()
    }

    func requestBatteryRead(timer: Timer) {
        geigerMeterClient.readBatteryLevel()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GeigerMeterViewController: GeigerClientDelegate {
    func clientDidUpdate(status: String) {
        self.status.text = status
    }
    
    func clientError(errorDescription: String) {
        
    }
    
    func radiationReadingArrived(radiation: Float) {
        meterView.radiationIndicatorValue = radiation
    }
    
    func clientDidUpdate(batteryLevel: Int) {
        battery.text = "Battery: \(batteryLevel)%"
    }
    
    func clientExecutedCommand() {
        
    }
    
}

