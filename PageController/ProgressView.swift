//
//  ProgressView.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

class ProgressView: UIView {
    
    // MARK: - Public vars
    var itemFrames = [CGRect]()
    var progress: CGFloat = 0.0 {
        didSet { setNeedsDisplay() }
    }
    lazy var color: CGColorRef = UIColor.brownColor().CGColor
    
    // MARK: - Private vars
    weak private var link: CADisplayLink?
    private var gap: CGFloat = 0.0
    private var step: CGFloat = 0.0
    private var sign = 1
    
    // MARK: - Public funcs
    func moveToPosition(position: Int, animation: Bool) {
        if animation == false {
            progress = CGFloat(position)
            return
        }
        let pos = CGFloat(position)
        gap = fabs(progress - pos)
        sign = progress > pos ? -1 : 1
        step = gap / 15.0
        link?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        let tempLink = CADisplayLink(target: self, selector: #selector(ProgressView.progressChanged))
        tempLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        link = tempLink
    }
    
    func progressChanged() {
        if gap > 0.000001 {
            gap -= step
            if gap < 0.0 {
                progress = blurredCeil(progress + CGFloat(sign) * step )
                return
            }
            progress += CGFloat(sign) * step
        } else {
            progress = blurredCeil(progress)
            link?.invalidate()
            link = nil
        }
    }
    
    private func blurredCeil(num: CGFloat) -> CGFloat {
        let p = num + 0.5 
        return floor(p)
    }
    
    // MARK: - Private funcs
    override func drawRect(rect: CGRect) {
        // Drawing code
        let ctx = UIGraphicsGetCurrentContext()
        let index = Int(progress)
        let rate = progress - CGFloat(index)
        let currentFrame = itemFrames[index]
        let currentWidth = currentFrame.size.width
        let nextIndex = (index + 1 < itemFrames.count) ? index + 1 : index
        let nextWidth = itemFrames[nextIndex].size.width
        let height = frame.size.height
        let constY = height / 2
        let currentX = currentFrame.origin.x
        let nextX = itemFrames[nextIndex].origin.x
        let startX = currentX + (nextX - currentX) * rate
        let endX = startX + currentWidth + (nextWidth - currentWidth) * rate
        CGContextMoveToPoint(ctx, startX, constY)
        CGContextAddLineToPoint(ctx, endX, constY)
        CGContextSetLineWidth(ctx, height)
        CGContextSetStrokeColorWithColor(ctx, color)
        CGContextStrokePath(ctx)
    }
    
}
