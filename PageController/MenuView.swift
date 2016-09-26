//
//  MenuView.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

@objc public protocol MenuViewDelegate: NSObjectProtocol {
    func menuView(_ menuView: MenuView, widthForItemAtIndex index: Int) -> CGFloat
    @objc optional func menuView(_ menuView: MenuView, didSelectedIndex index: Int, fromIndex currentIndex: Int)
    @objc optional func menuView(_ menuView: MenuView, itemMarginAtIndex index: Int) -> CGFloat
}

@objc public protocol MenuViewDataSource: NSObjectProtocol {
    func menuView(_ menuView: MenuView, titleAtIndex index: Int) -> String
    func numbersOfTitlesInMenuView(_ menuView: MenuView) -> Int
}

public enum MenuViewStyle {
    case `default`, line, flood, fooldHollow
}

open class MenuView: UIView, MenuItemDelegate {

    // MARK: - Public vars
    override open var frame: CGRect {
        didSet {
            guard contentView != nil else { return }

            let rightMargin = (rightView == nil) ? contentMargin : contentMargin + rightView!.frame.width
            let leftMargin  = (leftView == nil) ? contentMargin : contentMargin + leftView!.frame.width
            let contentWidth = contentView.frame.width + leftMargin + rightMargin
            
            let startX = (leftView != nil) ? leftView!.frame.origin.x : (contentView.frame.origin.x - contentMargin)
            
            // Make the contentView center, because system will change menuView's frame if it's a titleView.
            if (startX + contentWidth / 2 != bounds.width / 2) {
                let xOffset = (contentWidth - bounds.width) / 2
                contentView.frame.origin.x -= xOffset
                rightView?.frame.origin.x -= xOffset
                leftView?.frame.origin.x -= xOffset
            }
            
        }
    }
    
    open weak var leftView: UIView? {
        willSet {
            leftView?.removeFromSuperview()
        }
        didSet {
            if let lView = leftView {
                addSubview(lView)
            }
            resetFrames()
        }
    }
    
    open weak var rightView: UIView? {
        willSet {
            rightView?.removeFromSuperview()
        }
        didSet {
            if let rView = rightView {
                addSubview(rView)
            }
            resetFrames()
        }
    }
    
    open var contentMargin: CGFloat = 0.0 {
        didSet {
            guard contentView != nil else { return }
            resetFrames()
        }
    }
    
    open var style = MenuViewStyle.default
    open var fontName: String?
    open var progressHeight: CGFloat = 2.0
    open var normalSize: CGFloat = 15.0
    open var selectedSize: CGFloat = 18.0
    open var progressColor: UIColor?
    
    open weak var delegate: MenuViewDelegate?
    open weak var dataSource: MenuViewDataSource!
    open lazy var normalColor = UIColor.black
    open lazy var selectedColor = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    
    // MARK: - Private vars
    fileprivate weak var contentView: UIScrollView!
    fileprivate weak var progressView: ProgressView?
    fileprivate weak var selectedItem: MenuItem!
    fileprivate var itemFrames = [CGRect]()
    fileprivate let tagGap = 6250
    fileprivate var itemsCount: Int {
        return dataSource.numbersOfTitlesInMenuView(self)
    }
    
    open func reload() {
        itemFrames.removeAll()
        progressView?.removeFromSuperview()
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }

        addMenuItems()
        addProgressView()
    }
    
    // MARK: - Public funcs
    open func slideMenuAtProgress(_ progress: CGFloat) {
        progressView?.progress = progress
        let tag = Int(progress) + tagGap
        let rate = progress - CGFloat(tag - tagGap)
        let currentItem = viewWithTag(tag) as? MenuItem
        let nextItem = viewWithTag(tag + 1) as? MenuItem
        if rate == 0.0 {
            selectedItem.selected = false
            selectedItem = currentItem
            selectedItem.selected = true
            refreshContentOffset()
            return
        }
        currentItem?.rate = 1.0 - rate
        nextItem?.rate = rate
    }
    
    open func selectItemAtIndex(_ index: Int) {
        let tag = index + tagGap
        let currentIndex = selectedItem.tag - tagGap
        guard currentIndex != index && selectedItem != nil else { return }
        
        let menuItem = viewWithTag(tag) as! MenuItem
        selectedItem.selected = false
        selectedItem = menuItem
        selectedItem.selected = true
        progressView?.moveToPosition(index, animation: false)
        delegate?.menuView?(self, didSelectedIndex: index, fromIndex: currentIndex)
        refreshContentOffset()
    }
    
    // MARK: - Update Title
    open func updateTitle(_ title: String, atIndex index: Int, andWidth update: Bool) {
        guard index >= 0 && index < itemsCount else { return }
        let item = viewWithTag(tagGap + index) as? MenuItem
        item?.text = title
        guard update else { return }
        resetFrames()
    }
    
    // MARK: - Update Frames
    open func resetFrames() {

        var contentFrame = bounds
        if let rView = rightView {
            var rightFrame = rView.frame
            rightFrame.origin.x = contentFrame.width - rightFrame.width
            rightView?.frame = rightFrame
            contentFrame.size.width -= rightFrame.width
        }
        
        if let lView = leftView {
            var leftFrame = lView.frame
            leftFrame.origin.x = 0
            leftView?.frame = leftFrame
            contentFrame.origin.x += leftFrame.width
            contentFrame.size.width -= leftFrame.width
        }
        
        contentFrame.origin.x += contentMargin
        contentFrame.size.width -= contentMargin * 2
        contentView.frame = contentFrame
        resetFramesFromIndex(0)
        refreshContentOffset()
    }
    
    open func resetFramesFromIndex(_ index: Int) {
        itemFrames.removeAll()
        calculateFrames()
        for i in index ..< itemsCount {
            let item = viewWithTag(tagGap + i) as? MenuItem
            item?.frame = itemFrames[i]
        }
        if let progress = progressView {
            var pFrame = progress.frame
            pFrame.size.width = contentView.contentSize.width
            if progress.isKind(of: FloodView.self) {
                pFrame.origin.y = 0
            } else {
                pFrame.origin.y = frame.size.height - progressHeight
            }
            progress.frame = pFrame
            progress.itemFrames = itemFrames
            progress.setNeedsDisplay()
        }
    }
    
    // MARK: - Private funcs
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard contentView == nil else { return }
        addScollView()
        addMenuItems()
        addProgressView()
    }
    
    fileprivate func refreshContentOffset() {
        let itemFrame = selectedItem.frame
        let itemX = itemFrame.origin.x
        let width = contentView.frame.size.width
        let contentWidth = contentView.contentSize.width
        if itemX > (width / 2) {
            var targetX: CGFloat = itemFrame.origin.x - width/2 + itemFrame.size.width/2
            if (contentWidth - itemX) <= (width / 2) {
                targetX = contentWidth - width
            }
            if (targetX + width) > contentWidth {
                targetX = contentWidth - width
            }
            contentView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
        } else {
            contentView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
    
    // MARK: - Create Views
    fileprivate func addScollView() {
        let scrollViewFrame = CGRect(x: contentMargin, y: 0, width: frame.size.width - contentMargin * 2, height: frame.size.height)
        let scrollView = UIScrollView(frame: scrollViewFrame)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.scrollsToTop = false
        addSubview(scrollView)
        contentView = scrollView
    }
    
    fileprivate func addMenuItems() {
        calculateFrames()
        for index in 0 ..< itemsCount {
            let menuItemFrame = itemFrames[index]
            let menuItem = MenuItem(frame: menuItemFrame)
            menuItem.tag = index + tagGap
            menuItem.delegate = self
            menuItem.text = dataSource.menuView(self, titleAtIndex: index)
            menuItem.textColor = normalColor
            if let optionalFontName = fontName {
                menuItem.font = UIFont(name: optionalFontName, size: selectedSize)
            } else {
                menuItem.font = UIFont.systemFont(ofSize: selectedSize)
            }
            menuItem.normalSize    = normalSize
            menuItem.selectedSize  = selectedSize
            menuItem.normalColor   = normalColor
            menuItem.selectedColor = selectedColor
            menuItem.selected = (index == 0) ? true : false
            if index == 0 { selectedItem = menuItem }
            contentView.addSubview(menuItem)
        }
    }
    
    fileprivate func addProgressView() {
        var optionalType: ProgressView.Type?
        var hollow = false
        switch style {
            case .default: break
            case .line: optionalType = ProgressView.self
            case .fooldHollow:
                optionalType = FloodView.self
                hollow = true
            case .flood: optionalType = FloodView.self
        }
        if let viewType = optionalType {
            let pView = viewType.init()
            let height = (style == .line) ? progressHeight : frame.size.height
            let progressY = (style == .line) ? (frame.size.height - progressHeight) : 0
            pView.frame = CGRect(x: 0, y: progressY, width: contentView.contentSize.width, height: height)
            pView.itemFrames = itemFrames
            if (progressColor == nil) {
                progressColor = selectedColor
            }
            pView.color = (progressColor?.cgColor)!
            pView.backgroundColor = .clear
            if let fooldView = pView as? FloodView {
                fooldView.hollow = hollow
            }
            contentView.insertSubview(pView, at: 0)
            progressView = pView
        }
    }
    
    // MARK: - Calculate Frames
    fileprivate func calculateFrames() {
        var contentWidth: CGFloat = itemMarginAtIndex(0)
        for index in 0 ..< itemsCount {
            let itemWidth = delegate!.menuView(self, widthForItemAtIndex: index)
            let itemFrame = CGRect(x: contentWidth, y: 0, width: itemWidth, height: frame.size.height)
            itemFrames.append(itemFrame)
            contentWidth += itemWidth + itemMarginAtIndex(index + 1)
        }
        if contentWidth < contentView.frame.size.width {
            let distance = contentView.frame.size.width - contentWidth
            let itemMargin = distance / CGFloat(itemsCount + 1)
            for index in 0 ..< itemsCount {
                var itemFrame = itemFrames[index]
                itemFrame.origin.x += itemMargin * CGFloat(index + 1)
                itemFrames[index] = itemFrame
            }
            contentWidth = contentView.frame.size.width
        }
        contentView.contentSize = CGSize(width: contentWidth, height: frame.size.height)
    }
    
    fileprivate func itemMarginAtIndex(_ index: Int) -> CGFloat {
        if let itemMargin = delegate?.menuView?(self, itemMarginAtIndex: index) {
            return itemMargin
        }
        return 0.0
    }
    
    // MARK: - MenuItemDelegate
    func didSelectedMenuItem(_ menuItem: MenuItem) {
        if selectedItem == menuItem { return }
        let position = menuItem.tag - tagGap
        let currentIndex = selectedItem.tag - tagGap
        progressView?.moveToPosition(position, animation: true)
        delegate?.menuView?(self, didSelectedIndex: position, fromIndex: currentIndex)
        
        menuItem.selectWithAnimation(true)
        selectedItem.selectWithAnimation(false)
        selectedItem = menuItem
        refreshContentOffset()
    }
    
}
