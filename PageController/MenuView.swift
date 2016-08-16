//
//  MenuView.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

@objc public protocol MenuViewDelegate: NSObjectProtocol {
    func menuView(menuView: MenuView, widthForItemAtIndex index: Int) -> CGFloat
    optional func menuView(menuView: MenuView, didSelectedIndex index: Int, fromIndex currentIndex: Int)
    optional func menuView(menuView: MenuView, itemMarginAtIndex index: Int) -> CGFloat
}

@objc public protocol MenuViewDataSource: NSObjectProtocol {
    func menuView(menuView: MenuView, titleAtIndex index: Int) -> String
    func numbersOfTitlesInMenuView(menuView: MenuView) -> Int
}

public enum MenuViewStyle {
    case Default, Line, Flood, FooldHollow
}

public class MenuView: UIView, MenuItemDelegate {

    // MARK: - Public vars
    override public var frame: CGRect {
        didSet {
            guard contentView != nil else { return }

            let rightMargin = (rightView == nil) ? contentMargin : contentMargin + rightView!.frame.width
            let leftMargin  = (leftView == nil) ? contentMargin : contentMargin + leftView!.frame.width
            let contentWidth = CGRectGetWidth(contentView.frame) + leftMargin + rightMargin
            
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
    
    public weak var leftView: UIView? {
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
    
    public weak var rightView: UIView? {
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
    
    public var contentMargin: CGFloat = 0.0 {
        didSet {
            guard contentView != nil else { return }
            resetFrames()
        }
    }
    
    public var style = MenuViewStyle.Default
    public var fontName: String?
    public var progressHeight: CGFloat = 2.0
    public var normalSize: CGFloat = 15.0
    public var selectedSize: CGFloat = 18.0
    public var progressColor: UIColor?
    
    public weak var delegate: MenuViewDelegate?
    public weak var dataSource: MenuViewDataSource!
    public lazy var normalColor = UIColor.blackColor()
    public lazy var selectedColor = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    
    // MARK: - Private vars
    private weak var contentView: UIScrollView!
    private weak var progressView: ProgressView?
    private weak var selectedItem: MenuItem!
    private var itemFrames = [CGRect]()
    private let tagGap = 6250
    private var itemsCount: Int {
        return dataSource.numbersOfTitlesInMenuView(self)
    }
    
    public func reload() {
        itemFrames.removeAll()
        progressView?.removeFromSuperview()
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }

        addMenuItems()
        addProgressView()
    }
    
    // MARK: - Public funcs
    public func slideMenuAtProgress(progress: CGFloat) {
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
    
    public func selectItemAtIndex(index: Int) {
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
    public func updateTitle(title: String, atIndex index: Int, andWidth update: Bool) {
        guard index >= 0 && index < itemsCount else { return }
        let item = viewWithTag(tagGap + index) as? MenuItem
        item?.text = title
        guard update else { return }
        resetFrames()
    }
    
    // MARK: - Update Frames
    public func resetFrames() {

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
    
    public func resetFramesFromIndex(index: Int) {
        itemFrames.removeAll()
        calculateFrames()
        for i in index ..< itemsCount {
            let item = viewWithTag(tagGap + i) as? MenuItem
            item?.frame = itemFrames[i]
        }
        if let progress = progressView {
            var pFrame = progress.frame
            pFrame.size.width = contentView.contentSize.width
            if progress.isKindOfClass(FloodView.self) {
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
    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        guard contentView == nil else { return }
        addScollView()
        addMenuItems()
        addProgressView()
    }
    
    private func refreshContentOffset() {
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
            contentView.setContentOffset(CGPointMake(targetX, 0), animated: true)
        } else {
            contentView.setContentOffset(CGPointZero, animated: true)
        }
    }
    
    // MARK: - Create Views
    private func addScollView() {
        let scrollViewFrame = CGRect(x: contentMargin, y: 0, width: frame.size.width - contentMargin * 2, height: frame.size.height)
        let scrollView = UIScrollView(frame: scrollViewFrame)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clearColor()
        scrollView.scrollsToTop = false
        addSubview(scrollView)
        contentView = scrollView
    }
    
    private func addMenuItems() {
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
                menuItem.font = UIFont.systemFontOfSize(selectedSize)
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
    
    private func addProgressView() {
        var optionalType: ProgressView.Type?
        var hollow = false
        switch style {
            case .Default: break
            case .Line: optionalType = ProgressView.self
            case .FooldHollow:
                optionalType = FloodView.self
                hollow = true
            case .Flood: optionalType = FloodView.self
        }
        if let viewType = optionalType {
            let pView = viewType.init()
            let height = (style == .Line) ? progressHeight : frame.size.height
            let progressY = (style == .Line) ? (frame.size.height - progressHeight) : 0
            pView.frame = CGRect(x: 0, y: progressY, width: contentView.contentSize.width, height: height)
            pView.itemFrames = itemFrames
            if (progressColor == nil) {
                progressColor = selectedColor
            }
            pView.color = (progressColor?.CGColor)!
            pView.backgroundColor = .clearColor()
            if let fooldView = pView as? FloodView {
                fooldView.hollow = hollow
            }
            contentView.insertSubview(pView, atIndex: 0)
            progressView = pView
        }
    }
    
    // MARK: - Calculate Frames
    private func calculateFrames() {
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
    
    private func itemMarginAtIndex(index: Int) -> CGFloat {
        if let itemMargin = delegate?.menuView?(self, itemMarginAtIndex: index) {
            return itemMargin
        }
        return 0.0
    }
    
    // MARK: - MenuItemDelegate
    func didSelectedMenuItem(menuItem: MenuItem) {
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
