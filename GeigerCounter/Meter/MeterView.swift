//
//  MeterView.swift
//  GeigerCounter
//
//  Created by Pablo Caif on 10/2/18.
//  Copyright © 2018 Pablo Caif. All rights reserved.
//

import UIKit
import CoreGraphics

public class MeterView: UIView {
    private var maxIndicatorValue: CGFloat = 100.0
    private  var lastColor: CGColor?
    private weak var indicator: IndicatorLayer?
    private weak var meterTemplateLayer: MeterTemplateLayer?
    
    public var radiationIndicatorValue: Float = 0.0 {
        didSet {
            indicator?.value = CGFloat(radiationIndicatorValue)
            lastColor = indicator?.indicatorColor
            if lastColor == nil {
                lastColor = UIColor.green.cgColor
            }
            guard let toColor = indicator?.colorForValue(CGFloat(radiationIndicatorValue)) else {return}
            indicator?.indicatorColor = toColor
        
            let animation = createAnimation(fromValue: CGFloat(oldValue), toValue: CGFloat(radiationIndicatorValue), fromColor: lastColor!, toColor: toColor, time: 0.2)
            
            indicator?.add(animation, forKey: "value")
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let indicator = IndicatorLayer()
        layer.insertSublayer(indicator, at: 0)
        indicator.backgroundColor = UIColor.clear.cgColor
        indicator.shouldRasterize = true
        indicator.rasterizationScale = UIScreen.main.scale

        let templateLayer = MeterTemplateLayer()
        templateLayer.backgroundColor = UIColor.clear.cgColor
        templateLayer.shouldRasterize = true
        templateLayer.rasterizationScale = UIScreen.main.scale
        layer.addSublayer(templateLayer)
        self.meterTemplateLayer = templateLayer
        self.indicator = indicator
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        indicator?.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: frame.size.height)
        meterTemplateLayer?.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: frame.size.height)
    }


    public override func draw(_ rect: CGRect) {
        indicator?.setNeedsDisplay()
        meterTemplateLayer?.setNeedsDisplay()
    }

    private func createAnimation(fromValue: CGFloat, toValue: CGFloat, fromColor: CGColor, toColor: CGColor, time: CFTimeInterval) -> CAAnimationGroup {
        let valueAnimation = CABasicAnimation(keyPath: "value")
        valueAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        valueAnimation.fromValue = fromValue
        valueAnimation.fillMode = kCAFillModeForwards
        valueAnimation.duration = time
        valueAnimation.beginTime = 0.0
        
        let colorAnimation = CABasicAnimation(keyPath: "indicatorColor")
        colorAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        colorAnimation.fromValue = fromColor
        colorAnimation.duration = time
        colorAnimation.beginTime = 0.0
        colorAnimation.fillMode = kCAFillModeForwards
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [valueAnimation, colorAnimation]
        animationGroup.duration = time
        return animationGroup
    }

}

