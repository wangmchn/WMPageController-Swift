//
//  FooldView.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

class FloodView: ProgressView {

    // MARK: - Vars
    var hollow = false
    fileprivate var margin: CGFloat = 0.0
    fileprivate var radius: CGFloat = 0.0
    fileprivate var height: CGFloat = 0.0

    // MARK: - Private funcs
    override func willMove(toSuperview newSuperview: UIView?) {
        height = frame.size.height
        margin = height * 0.15
        radius = (height - margin * 2.0) / 2.0
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let currentIndex = Int(progress)
        let rate = progress - CGFloat(currentIndex)
        let nextIndex = (currentIndex + 1) >= itemFrames.count ? currentIndex : currentIndex + 1
        let currentFrame = itemFrames[currentIndex]
        let currentWidth = currentFrame.size.width
        let currentX = currentFrame.origin.x
        let nextWidth = itemFrames[nextIndex].size.width
        let nextX = self.itemFrames[nextIndex].origin.x
        let startX = currentX + (nextX - currentX) * rate
        let endX = startX + currentWidth + (nextWidth - currentWidth) * rate
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.translateBy(x: 0.0, y: height)
        ctx?.scaleBy(x: 1.0, y: -1.0)
        ctx?.addArc(center: CGPoint(x: startX + radius, y: height / 2.0), radius: radius, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi / 2) * 3, clockwise: false)
        // CGContextAddArc(ctx, startX + radius, height / 2.0, radius, CGFloat(M_PI_2), CGFloat(M_PI_2) * 3, 0)
        ctx?.addLine(to: CGPoint(x: endX - radius, y: margin))
        ctx?.addArc(center: CGPoint(x: endX - radius, y: height / 2.0), radius: radius, startAngle: CGFloat(-Double.pi / 2), endAngle: CGFloat(Double.pi / 2), clockwise: false)
        // CGContextAddArc(ctx, endX - radius, height / 2.0, radius, CGFloat(-M_PI_2), CGFloat(M_PI_2), 0)
        ctx?.closePath()
        if hollow == true {
            ctx?.setStrokeColor(color)
            ctx?.strokePath()
            return
        }
        ctx?.closePath()
        ctx?.setFillColor(color)
        ctx?.fillPath()
    }
    
}
