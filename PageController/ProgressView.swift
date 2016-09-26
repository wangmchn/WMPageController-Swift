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
    lazy var color: CGColor = UIColor.brown.cgColor
    
    // MARK: - Private vars
    weak fileprivate var link: CADisplayLink?
    fileprivate var gap: CGFloat = 0.0
    fileprivate var step: CGFloat = 0.0
    fileprivate var sign = 1
    
    // MARK: - Public funcs
    func moveToPosition(_ position: Int, animation: Bool) {
        if animation == false {
            progress = CGFloat(position)
            return
        }
        let pos = CGFloat(position)
        gap = fabs(progress - pos)
        sign = progress > pos ? -1 : 1
        step = gap / 15.0
        link?.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
        let tempLink = CADisplayLink(target: self, selector: #selector(ProgressView.progressChanged))
        tempLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
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
    
    fileprivate func blurredCeil(_ num: CGFloat) -> CGFloat {
        let p = num + 0.5 
        return floor(p)
    }
    
    // MARK: - Private funcs
    override func draw(_ rect: CGRect) {
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
        ctx?.move(to: CGPoint(x: startX, y: constY))
        ctx?.addLine(to: CGPoint(x: endX, y: constY))
        ctx?.setLineWidth(height)
        ctx?.setStrokeColor(color)
        ctx?.strokePath()
    }
    
}
