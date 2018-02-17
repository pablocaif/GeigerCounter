//
// Created by Pablo Caif on 12/2/18.
// Copyright (c) 2018 Pablo Caif. All rights reserved.
//

import UIKit

extension CALayer {

    public func calculateAngle(for value:CGFloat, maxValue: CGFloat) -> CGFloat {
        return ((value * CGFloat.pi) / maxValue) + CGFloat.pi
    }

    public func calculateRadialCoordinate(forAngle angle: CGFloat, center: CGPoint,radius: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)

        return CGPoint(x: x, y: y)
    }
}
