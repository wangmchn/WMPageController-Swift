//
//  MenuView.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

@objc public protocol MenuViewDelegate: NSObjectProtocol {
    func menuView(menuView: MenuView, widthForItemAtIndex index: NSInteger) -> CGFloat
    optional func menuView(menuView: MenuView, didSelectedIndex index: NSInteger, fromIndex currentIndex: NSInteger)
    optional func menuView(menuView: MenuView, itemMarginAtIndex index: NSInteger) -> CGFloat
}

public enum MenuViewStyle {
    case Default, Line, Flood, FooldHollow
}

public class MenuView: UIView, MenuItemDelegate {

    // MARK: - Public vars
    public var itemTitles = [String]()
    public var style = MenuViewStyle.Default
    public var fontName: String?
    public var progressHeight: CGFloat = 2.0
    public var normalSize: CGFloat = 15.0
    public var selectedSize: CGFloat = 18.0
    public var progressColor: UIColor?
    public weak var delegate: MenuViewDelegate?
    public lazy var normalColor = UIColor.blackColor()
    public lazy var selectedColor = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    public lazy var bgColor = UIColor(red: 172.0/255.0, green: 165.0/255.0, blue: 162.0/255.0, alpha: 1.0)
    
    // MARK: - Private vars
    private weak var contentView: UIScrollView!
    private weak var progressView: ProgressView?
    private weak var selectedItem: MenuItem!
    private var itemFrames = [CGRect]()
    private let tagGap = 6250
    
    // MARK: - Public funcs
    convenience init(frame: CGRect, titles: [String]) {
        self.init(frame: frame)
        itemTitles = titles
    }
    
    func slideMenuAtProgress(progress: CGFloat) {
        progressView?.progress = progress
        let tag = NSInteger(progress) + tagGap
        var rate = progress - CGFloat(tag - tagGap)
        let currentItem = viewWithTag(tag) as? MenuItem
        let nextItem = viewWithTag(tag + 1) as? MenuItem
        if rate == 0.0 {
            rate = 1.0
            selectedItem.selected = false
            selectedItem = currentItem
            selectedItem.selected = true
            refreshContentOffset()
            return
        }
        currentItem?.rate = 1.0 - rate
        nextItem?.rate = rate
    }
    
    func selectItemAtIndex(index: NSInteger) {
        let tag = index + tagGap
        let currentIndex = selectedItem.tag - tagGap
        let menuItem = viewWithTag(tag) as! MenuItem
        selectedItem.selected = false
        selectedItem = menuItem
        selectedItem.selected = true
        progressView?.moveToPosition(index, animation: false)
        delegate?.menuView?(self, didSelectedIndex: index, fromIndex: currentIndex)
        refreshContentOffset()
    }
    
    // MARK: - Private funcs
    override public func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
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
    
    private func addScollView() {
        let scrollViewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        let scrollView = UIScrollView(frame: scrollViewFrame)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = bgColor
        scrollView.scrollsToTop = false
        addSubview(scrollView)
        contentView = scrollView
    }
    
    private func addMenuItems() {
        calculateFrames()
        for index in 0 ..< itemTitles.count {
            let menuItemFrame = itemFrames[index]
            let menuItem = MenuItem(frame: menuItemFrame)
            menuItem.tag = index + tagGap
            menuItem.delegate = self
            menuItem.text = itemTitles[index]
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
                optionalType = FooldView.self
                hollow = true
            case .Flood: optionalType = FooldView.self
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
            if let fooldView = pView as? FooldView {
                fooldView.hollow = hollow
            }
            contentView.insertSubview(pView, atIndex: 0)
            progressView = pView
        }
    }
    
    private func calculateFrames() {
        var contentWidth: CGFloat = itemMarginAtIndex(0)
        for index in 0 ..< itemTitles.count {
            let itemWidth = delegate!.menuView(self, widthForItemAtIndex: index)
            let itemFrame = CGRect(x: contentWidth, y: 0, width: itemWidth, height: frame.size.height)
            itemFrames.append(itemFrame)
            contentWidth += itemWidth + itemMarginAtIndex(index + 1)
        }
        if contentWidth < frame.size.width {
            let distance = frame.size.width - contentWidth
            let itemMargin = distance / CGFloat(itemTitles.count + 1)
            for index in 0 ..< itemTitles.count {
                var itemFrame = itemFrames[index]
                itemFrame.origin.x += itemMargin * CGFloat(index + 1)
                itemFrames[index] = itemFrame
            }
            contentWidth = frame.size.width
        }
        contentView.contentSize = CGSize(width: contentWidth, height: frame.size.height)
    }
    
    private func itemMarginAtIndex(index: NSInteger) -> CGFloat {
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
