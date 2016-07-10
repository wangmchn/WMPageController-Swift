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
    private var margin: CGFloat = 0.0
    private var radius: CGFloat = 0.0
    private var height: CGFloat = 0.0

    // MARK: - Private funcs
    override func willMoveToSuperview(newSuperview: UIView?) {
        height = frame.size.height
        margin = height * 0.15
        radius = (height - margin * 2.0) / 2.0
    }
    
    override func drawRect(rect: CGRect) {
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
        CGContextTranslateCTM(ctx, 0.0, height)
        CGContextScaleCTM(ctx, 1.0, -1.0)
        CGContextAddArc(ctx, startX + radius, height / 2.0, radius, CGFloat(M_PI_2), CGFloat(M_PI_2) * 3, 0)
        CGContextAddLineToPoint(ctx, endX - radius, margin)
        CGContextAddArc(ctx, endX - radius, height / 2.0, radius, CGFloat(-M_PI_2), CGFloat(M_PI_2), 0)
        CGContextClosePath(ctx)
        if hollow == true {
            CGContextSetStrokeColorWithColor(ctx, color)
            CGContextStrokePath(ctx)
            return
        }
        CGContextClosePath(ctx)
        CGContextSetFillColorWithColor(ctx, color)
        CGContextFillPath(ctx)
    }
    
}
