//
//  PageController.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

public enum CachePolicy: Int {
    case NoLimit    = 0
    case LowMemory  = 1
    case Balanced   = 3
    case High       = 5
}

public let WMPageControllerDidMovedToSuperViewNotification = "WMPageControllerDidMovedToSuperViewNotification"
public let WMPageControllerDidFullyDisplayedNotification = "WMPageControllerDidFullyDisplayedNotification"

public class PageController: UIViewController, UIScrollViewDelegate, MenuViewDelegate {
    
    // MARK: - Public vars
    public var viewControllerClasses: [UIViewController.Type]!
    public var titles: [String]!
    public var values: NSArray?
    public var keys: [String]?
    public var progressColor: UIColor?
    public var progressHeight: CGFloat = 2.0
    public var itemMargin: CGFloat = 0.0
    public var menuViewStyle = MenuViewStyle.Default
    public var titleFontName: String?
    public var pageAnimatable   = false
    public var postNotification = false
    public var bounces = false
    public var titleSizeSelected: CGFloat  = 18.0
    public var titleSizeNormal: CGFloat    = 15.0
    public var menuHeight: CGFloat         = 30.0
    public var menuItemWidth: CGFloat      = 65.0
    public weak var contentView: UIScrollView?
    public weak var menuView: MenuView?

    public var itemsWidths: [CGFloat]? {
        didSet { assert(itemsWidths?.count == viewControllerClasses.count, "`itemsWidths's count` must equal to `view controllers's count`") }
    }
    
    public var currentViewController: UIViewController? {
        get { return currentController }
    }
    
    public var selectedIndex: Int {
        set {
            indexInside = newValue
            menuView?.selectItemAtIndex(newValue)
        }
        get { return indexInside }
    }
    
    public var viewFrame = CGRect() {
        didSet {
            if let _ = menuView {
                viewDidLayoutSubviews()
            }
        }
    }
    
    public var itemsMargins: [CGFloat]? {
        didSet { assert(itemsMargins?.count == viewControllerClasses.count + 1, "`itemsMargins's count` must equal to `view controllers's count + 1`") }
    }
    
    public var cachePolicy: CachePolicy = .NoLimit {
        didSet { memCache.countLimit = cachePolicy.rawValue }
    }
    
    public lazy var titleColorSelected = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    public lazy var titleColorNormal = UIColor.blackColor()
    public lazy var menuBGColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    
    // MARK: - Private vars
    private var currentController: UIViewController?
    private var memoryWarningCount = 0
    private var animate = false
    private var viewHeight: CGFloat = 0.0
    private var viewWidth: CGFloat = 0.0
    private var viewX: CGFloat = 0.0
    private var viewY: CGFloat = 0.0
    private var indexInside = 0
    private var targetX: CGFloat = 0.0
    
    lazy private var displayingControllers = NSMutableDictionary()
    lazy private var memCache = NSCache()
    lazy private var childViewFrames = [CGRect]()
    
    // MARK: - Life cycle
    public convenience init(vcClasses: [UIViewController.Type], theirTitles: [String]) {
        self.init()
        assert(vcClasses.count == theirTitles.count, "`vcClasses.count` must equal to `titles.count`")
        titles = theirTitles
        viewControllerClasses = vcClasses
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        calculateSize()
        edgesForExtendedLayout = UIRectEdge.None
        view.backgroundColor = .whiteColor()
        addScrollView()
        addViewControllerAtIndex(indexInside)
        currentController = displayingControllers[indexInside] as? UIViewController
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculateSize()
        let scrollViewFrame = CGRect(x: viewX, y: viewY + menuHeight, width: viewWidth, height: viewHeight)
        contentView?.frame = scrollViewFrame
        contentView?.contentSize = CGSize(width: CGFloat(titles.count) * viewWidth, height: 0)
        contentView?.contentOffset = CGPoint(x: CGFloat(indexInside) * viewWidth, y: 0)
        currentController?.view.frame = childViewFrames[indexInside]
        resetMenuView()
        view.layoutIfNeeded()
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        postFullyDisplayedNotificationWithIndex(indexInside)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        memoryWarningCount++
        cachePolicy = CachePolicy.LowMemory
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "growCachePolicyAfterMemoryWarning", object: nil)
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "growCachePolicyToHigh", object: nil)
        memCache.removeAllObjects()
        if memoryWarningCount < 3 {
            performSelector("growCachePolicyAfterMemoryWarning", withObject: nil, afterDelay: 3.0, inModes: [NSRunLoopCommonModes])
        }
    }

    // MARK: - Private funcs
    private func calculateSize() {
        if viewFrame == CGRectZero {
            viewWidth  = view.frame.size.width
            viewHeight = view.frame.size.height - menuHeight
        } else {
            viewWidth = viewFrame.size.width
            viewHeight = viewFrame.size.height
        }
        viewX = viewFrame.origin.x
        viewY = viewFrame.origin.y
        childViewFrames.removeAll()
        for index in 0 ..< viewControllerClasses.count {
            let viewControllerFrame = CGRect(x: CGFloat(index) * viewWidth, y: 0, width: viewWidth, height: viewHeight)
            childViewFrames.append(viewControllerFrame)
        }
    }
    
    private func addScrollView() {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = bounces
        view.addSubview(scrollView)
        contentView = scrollView
    }
    
    private func addMenuView() {
        let menuViewFrame = CGRect(x: viewX, y: viewY, width: viewWidth, height: menuHeight)
        let menu = MenuView(frame: menuViewFrame, titles: titles)
        menu.delegate = self
        menu.bgColor = menuBGColor
        menu.normalSize = titleSizeNormal
        menu.selectedSize = titleSizeSelected
        menu.normalColor = titleColorNormal
        menu.selectedColor = titleColorSelected
        menu.style = menuViewStyle
        menu.progressHeight = progressHeight
        menu.progressColor = progressColor
        menu.fontName = titleFontName
        view.addSubview(menu)
        menuView = menu
        if indexInside != 0 {
            menuView?.selectItemAtIndex(indexInside)
        }
    }
    
    private func postMovedToSuperViewNotificationWithIndex(index: NSInteger) {
        guard postNotification else { return }
        let info = ["index": index, "title": titles[index]]
        NSNotificationCenter.defaultCenter().postNotificationName(WMPageControllerDidMovedToSuperViewNotification, object: info)
    }
    
    private func postFullyDisplayedNotificationWithIndex(index: NSInteger) {
        guard postNotification else { return }
        let info = ["index": index, "title": titles[index]]
        NSNotificationCenter.defaultCenter().postNotificationName(WMPageControllerDidFullyDisplayedNotification, object: info)
    }
    
    private func layoutChildViewControllers() {
        let currentPage = NSInteger(contentView!.contentOffset.x / viewWidth)
        let start = currentPage == 0 ? currentPage : (currentPage - 1)
        let end = (currentPage == viewControllerClasses.count - 1) ? currentPage : (currentPage + 1)
        for index in start ... end {
            let viewControllerFrame = childViewFrames[index]
            var vc = displayingControllers.objectForKey(index)
            if inScreen(viewControllerFrame) {
                if vc == nil {
                    vc = memCache.objectForKey(index)
                    if let viewController = vc as? UIViewController {
                        addCachedViewController(viewController, atIndex: index)
                    } else {
                        addViewControllerAtIndex(index)
                    }
                    postMovedToSuperViewNotificationWithIndex(index)
                }
            } else {
                if let viewController = vc as? UIViewController {
                    removeViewController(viewController, atIndex: index)
                }
            }
        }
    }
    
    private func addCachedViewController(viewController: UIViewController, atIndex index: NSInteger) {
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames[index]
        viewController.didMoveToParentViewController(self)
        contentView?.addSubview(viewController.view)
        displayingControllers.setObject(viewController, forKey: index)
    }
    
    private func addViewControllerAtIndex(index: NSInteger) {
        let vcClass = viewControllerClasses[index]
        let viewController = vcClass.init()
        if let optionalKeys = keys {
            viewController.setValue(values?[index], forKey: optionalKeys[index])
        }
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames[index]
        viewController.didMoveToParentViewController(self)
        contentView?.addSubview(viewController.view)
        displayingControllers.setObject(viewController, forKey: index)
    }
    
    private func removeViewController(viewController: UIViewController, atIndex index: NSInteger) {
        viewController.view.removeFromSuperview()
        viewController.willMoveToParentViewController(nil)
        viewController.removeFromParentViewController()
        displayingControllers.removeObjectForKey(index)
        if memCache.objectForKey(index) == nil {
            memCache.setObject(viewController, forKey: index)
        }
    }
    
    private func inScreen(frame: CGRect) -> Bool {
        let x = frame.origin.x
        let ScreenWidth = contentView!.frame.size.width
        let contentOffsetX = contentView!.contentOffset.x
        if (CGRectGetMaxX(frame) > contentOffsetX) && (x - contentOffsetX < ScreenWidth) {
            return true
        }
        return false
    }
    
    private func resetMenuView() {
        let oldMenuView = menuView
        addMenuView()
        oldMenuView?.removeFromSuperview()
    }
    
    private func growCachePolicyAfterMemoryWarning() {
        cachePolicy = CachePolicy.Balanced
        performSelector("growCachePolicyToHigh", withObject: nil, afterDelay: 2.0, inModes: [NSRunLoopCommonModes])
    }
    
    private func growCachePolicyToHigh() {
        cachePolicy = CachePolicy.High
    }
    
    // MARK: - UIScrollView Delegate
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        layoutChildViewControllers()
        guard animate else { return }
        var contentOffsetX = contentView!.contentOffset.x
        if contentOffsetX < 0.0 {
            contentOffsetX = 0.0
        }
        if contentOffsetX > (scrollView.contentSize.width - viewWidth) {
            contentOffsetX = scrollView.contentSize.width - viewWidth
        }
        let rate = contentOffsetX / viewWidth
        menuView?.slideMenuAtProgress(rate)
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        animate = true
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        indexInside = NSInteger(contentView!.contentOffset.x / viewWidth)
        currentController = displayingControllers[indexInside] as? UIViewController
        postFullyDisplayedNotificationWithIndex(indexInside)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        indexInside = NSInteger(contentView!.contentOffset.x / viewWidth)
        currentController = displayingControllers[indexInside] as? UIViewController
        postFullyDisplayedNotificationWithIndex(indexInside)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        let rate = targetX / viewWidth
        menuView?.slideMenuAtProgress(rate)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetX = targetContentOffset.memory.x
    }
    
    // MARK: - MenuViewDelegate
    public func menuView(menuView: MenuView, didSelectedIndex index: NSInteger, fromIndex currentIndex: NSInteger) {
        let gap = labs(index - currentIndex)
        animate = false
        let targetPoint = CGPoint(x: CGFloat(index) * viewWidth, y: 0)
        let animatable = gap > 1 ? false : pageAnimatable
        contentView?.setContentOffset(targetPoint, animated: animatable)
        if animatable == false {
            layoutChildViewControllers()
            currentController = displayingControllers[index] as? UIViewController
            postFullyDisplayedNotificationWithIndex(index)
            indexInside = index
        }
    }
    
    public func menuView(menuView: MenuView, widthForItemAtIndex index: NSInteger) -> CGFloat {
        if let widths = itemsWidths {
            return widths[index]
        }
        return menuItemWidth
    }
    
    public func menuView(menuView: MenuView, itemMarginAtIndex index: NSInteger) -> CGFloat {
        if let margins = itemsMargins {
            return margins[index]
        }
        return itemMargin
    }
    
}
