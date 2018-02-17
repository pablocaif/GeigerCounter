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
    var timer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer(timeInterval: 1.0, repeats: true, block: updateValue)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateValue(timer: Timer) {
        let value = CGFloat(arc4random() % 100)
        meterView.value = value
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
