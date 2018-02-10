//
//  MeterView.swift
//  GeigerCounter
//
//  Created by Pablo Caif on 10/2/18.
//  Copyright © 2018 Pablo Caif. All rights reserved.
//

import UIKit

class MeterView: UIView {

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let centre = CGPoint(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
        
        //let arch = UIBezierPath(arcCenter: centre, radius: centre.x * 0.95, startAngle: CGFloat.pi, endAngle: CGFloat(0.0), clockwise: true)
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.addArc(center: centre, radius: centre.x * 0.95, startAngle: CGFloat.pi, endAngle: CGFloat(0.0), clockwise: false)
        context?.strokePath()
    }
 

}
