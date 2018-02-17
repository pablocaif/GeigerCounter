//
// Created by Pablo Caif on 12/2/18.
// Copyright (c) 2018 Pablo Caif. All rights reserved.
//

import UIKit

public class MeterTemplateLayer: CALayer {

    var segments = 20.0
    var meterColor = UIColor.lightGray

    public override func draw(in ctx: CGContext) {
        ctx.setShouldAntialias(true)
        let centre = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
        let radius = centre.x * 0.95

        drawMeter(context: ctx, centre: centre, radius: radius)
        drawMarkers(context: ctx, radius: radius, centre: centre)

        drawCircle(context: ctx, centre: centre, dotRadius: bounds.size.width * 0.1, color: UIColor.darkGray.cgColor)
        drawCircle(context: ctx, centre: centre, dotRadius: bounds.size.width * 0.07, color: UIColor.lightGray.cgColor)
    }

    private func drawCircle(context: CGContext, centre: CGPoint, dotRadius: CGFloat, color: CGColor) {
        context.setLineWidth(1.0)
        context.addEllipse(in: CGRect(x: centre.x - (dotRadius / 2.0), y: centre.y - (dotRadius / 2.0), width: dotRadius, height: dotRadius))

        context.setFillColor(color)
        context.fillPath()
        context.strokePath()
    }

    private func drawMarkers(context: CGContext, radius: CGFloat, centre: CGPoint) {
        let angleStep = CGFloat.pi / CGFloat(segments)
        var angle: CGFloat = CGFloat.pi
        var counter = 0
        context.setLineWidth(4.0)
        context.setStrokeColor(meterColor.cgColor)

        while angle <= CGFloat.pi * 2 {
            var markerLength = radius * 0.1
            if counter % 2 == 0 {
                markerLength *= 2
            }
            
            let markerRadius = radius * CGFloat(0.92)
            let outerRadialPoint = calculateRadialCoordinate(forAngle: angle, center: centre, radius: markerRadius)
            let inerRadialPoint = calculateRadialCoordinate(forAngle: angle, center: centre, radius: markerRadius - markerLength)

            context.move(to: outerRadialPoint)
            context.addLine(to: inerRadialPoint)
            context.strokePath()

            angle += angleStep
            counter += 1
        }
    }

    private func drawMeter(context: CGContext, centre: CGPoint, radius: CGFloat) {
        context.setLineWidth(4.0)
        context.setStrokeColor(meterColor.cgColor)
        context.addArc(center: centre, radius: radius, startAngle: CGFloat(0.0), endAngle: CGFloat.pi, clockwise: true)
        context.strokePath()
    }
}
