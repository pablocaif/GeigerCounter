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
    
    //var timer: Timer?
    let geigerMeterClient = GeigerMeterClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // timer = Timer(timeInterval: 1.0, repeats: true, block: updateValue)
        //RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
        geigerMeterClient.delegate = self
        geigerMeterClient.startReading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    func updateValue(timer: Timer?) {
//        let value = Float(arc4random() % 100)
//        meterView.radiationIndicatorValue = value
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        geigerMeterClient.stopReading()
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
    
    func cliendDidUpdate(batteryLevel: Float) {
        battery.text = "Battery: \(batteryLevel)%"
    }
    
    
}

