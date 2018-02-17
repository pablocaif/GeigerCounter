//
//  IndicatorLayer.swift
//  GeigerCounter
//
//  Created by Pablo Caif on 11/2/18.
//  Copyright © 2018 Pablo Caif. All rights reserved.
//

import UIKit

public class IndicatorLayer: CALayer {
    var maxValue: CGFloat = 100.0
    @objc var value: CGFloat = 0.0
    @objc var indicatorColor = UIColor.green.cgColor
    
    var greenLevel: CGFloat = 25
    var orangeLevel: CGFloat = 65
    
    public override class func needsDisplay(forKey key: String) -> Bool {
        if key == "value" {
            return true
        }
        return CALayer.needsDisplay(forKey: key)
    }
    
    public override func draw(in ctx: CGContext) {
        ctx.setShouldAntialias(true)
        let center = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
        let radius = frame.size.height / 2.0 * 0.94
        let color = indicatorColor
        
        //Lower left border
        ctx.setStrokeColor(color)
        ctx.setLineWidth(2.0)
        ctx.move(to: center)
        ctx.addLine(to: CGPoint(x: center.x - (bounds.size.width * 0.48), y: center.y))

        //Arc
        let angle = calculateAngle(for: value, maxValue: maxValue)
        ctx.addArc(center: center, radius: radius, startAngle: CGFloat.pi, endAngle: angle, clockwise: false)
        
        //Closing area
        ctx.addLine(to: center)
        ctx.setFillColor(color)
        ctx.closePath()
        ctx.fillPath()
        ctx.strokePath()

        let radialPoint = calculateRadialCoordinate(forAngle: angle, center: center, radius: radius * 0.94)

        ctx.move(to: center)
        ctx.addLine(to: radialPoint)
        ctx.setLineWidth(5.0)
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineCap(CGLineCap.round)
        ctx.strokePath()
    }

    public func colorForValue(_ value: CGFloat) -> CGColor {
        if value <= greenLevel {
            return UIColor.green.cgColor
        } else if value > greenLevel && value <= orangeLevel {
            return UIColor.orange.cgColor
        }
        return UIColor.red.cgColor
    }

}
