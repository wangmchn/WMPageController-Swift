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

public enum PreloadPolicy: Int {
    case Never      = 0
    case Neighbour  = 1
    case Near       = 2
}

public let WMPageControllerDidMovedToSuperViewNotification = "WMPageControllerDidMovedToSuperViewNotification"
public let WMPageControllerDidFullyDisplayedNotification = "WMPageControllerDidFullyDisplayedNotification"

@objc public protocol PageControllerDataSource: NSObjectProtocol {
    optional func numberOfControllersInPageController(pageController: PageController) -> Int
    optional func pageController(pageController: PageController, viewControllerAtIndex index: Int) -> UIViewController
    optional func pageController(pageController: PageController, titleAtIndex index: Int) -> String
}

@objc public protocol PageControllerDelegate: NSObjectProtocol {
    optional func pageController(pageController: PageController, lazyLoadViewController viewController: UIViewController, withInfo info: NSDictionary)
    optional func pageController(pageController: PageController, willCachedViewController viewController: UIViewController, withInfo info: NSDictionary)
    optional func pageController(pageController: PageController, willEnterViewController viewController: UIViewController, withInfo info: NSDictionary)
    optional func pageController(pageController: PageController, didEnterViewController viewController: UIViewController, withInfo info: NSDictionary)
}

public class ContentView: UIScrollView, UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let wrapperView = NSClassFromString("UITableViewWrapperView"), otherGestureView = otherGestureRecognizer.view else { return false }
        
        if otherGestureView.isKindOfClass(wrapperView) && (otherGestureRecognizer is UIPanGestureRecognizer) {
            return true
        }
        return false
    }
    
}

public class PageController: UIViewController, UIScrollViewDelegate, MenuViewDelegate, MenuViewDataSource, PageControllerDelegate, PageControllerDataSource {
    
    // MARK: - Public vars
    public weak var dataSource: PageControllerDataSource?
    public weak var delegate: PageControllerDelegate?
    
    public var viewControllerClasses: [UIViewController.Type]?
    public var titles: [String]?
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
    public var showOnNavigationBar = false
    public var startDragging = false
    public var titleSizeSelected: CGFloat  = 18.0
    public var titleSizeNormal: CGFloat    = 15.0
    public var menuHeight: CGFloat         = 30.0
    public var menuItemWidth: CGFloat      = 65.0
    public weak var contentView: ContentView?
    public weak var menuView: MenuView?

    public var itemsWidths: [CGFloat]?
    
    public private(set) var currentViewController: UIViewController?
    
    public var selectedIndex: Int {
        set {
            _selectedIndex = newValue
            menuView?.selectItemAtIndex(newValue)
        }
        get { return _selectedIndex }
    }
    
    public var menuViewContentMargin: CGFloat = 0.0 {
        didSet {
            guard let menu = menuView else { return }
            menu.contentMargin = oldValue
        }
    }
    
    public var viewFrame = CGRect() {
        didSet {
            if let _ = menuView {
                hasInit = false
                viewDidLayoutSubviews()
            }
        }
    }
    
    public var itemsMargins: [CGFloat]?
    public var preloadPolicy: PreloadPolicy = .Never
    
    public var cachePolicy: CachePolicy = .NoLimit {
        didSet { memCache.countLimit = cachePolicy.rawValue }
    }
    
    public lazy var titleColorSelected = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    public lazy var titleColorNormal = UIColor.blackColor()
    public lazy var menuBGColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    
    override public var edgesForExtendedLayout: UIRectEdge {
        didSet {
            hasInit = false
            viewDidLayoutSubviews()
        }
    }
    
    // MARK: - Private vars
    private var memoryWarningCount = 0
    private var viewHeight: CGFloat = 0.0
    private var viewWidth: CGFloat = 0.0
    private var viewX: CGFloat = 0.0
    private var viewY: CGFloat = 0.0
    private var _selectedIndex = 0
    private var targetX: CGFloat = 0.0
    private var superviewHeight: CGFloat = 0.0
    private var hasInit = false
    private var shouldNotScroll = false
    private var initializedIndex = -1
    private var controllerCount  = -1
    
    private var childControllersCount: Int {
        if controllerCount == -1 {
            if let count = dataSource?.numberOfControllersInPageController?(self) {
                controllerCount = count
            } else {
                controllerCount = (viewControllerClasses?.count ?? 0)
            }
        }
        return controllerCount
    }
    
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
        view.backgroundColor = .whiteColor()
        guard childControllersCount > 0 else { return }

        calculateSize()
        addScrollView()
        addViewControllerAtIndex(_selectedIndex)
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        addMenuView()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard childControllersCount > 0 else { return }
        
        let oldSuperviewHeight = superviewHeight
        superviewHeight = view.frame.size.height
        guard (!hasInit || superviewHeight != oldSuperviewHeight) && (view.window != nil) else { return }
        
        calculateSize()
        adjustScrollViewFrame()
        adjustMenuViewFrame()
        removeSuperfluousViewControllersIfNeeded()
        currentViewController?.view.frame = childViewFrames[_selectedIndex]
        hasInit = true
        view.layoutIfNeeded()
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        guard childControllersCount > 0 else { return }
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        memoryWarningCount += 1
        cachePolicy = CachePolicy.LowMemory
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(PageController.growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(PageController.growCachePolicyToHigh), object: nil)
        memCache.removeAllObjects()
        if memoryWarningCount < 3 {
            performSelector(#selector(PageController.growCachePolicyAfterMemoryWarning), withObject: nil, afterDelay: 3.0, inModes: [NSRunLoopCommonModes])
        }
    }
    
    // MARK: - Reload
    public func reloadData() {
        clearDatas()
        resetScrollView()
        memCache.removeAllObjects()
        viewDidLayoutSubviews()
        resetMenuView()
    }
    
    // MARK: - Update Title
    public func updateTitle(title: String, atIndex index: Int) {
        menuView?.updateTitle(title, atIndex: index, andWidth: false)
    }
    
    public func updateTitle(title: String, atIndex index: Int, andWidth width: CGFloat) {
        if var widths = itemsWidths {
            guard index < widths.count else { return }
            widths[index] = width
            itemsWidths = widths
        } else {
            var widths = [CGFloat]()
            for i in 0 ..< childControllersCount {
                let newWidth = (i == index) ? width : menuItemWidth
                widths.append(newWidth)
            }
            itemsWidths = widths
        }
        menuView?.updateTitle(title, atIndex: index, andWidth: true)
    }
    
    // MARK: - Data Source
    private func initializeViewControllerAtIndex(index: Int) -> UIViewController {
        if let viewController = dataSource?.pageController?(self, viewControllerAtIndex: index) {
            return viewController
        }
        return viewControllerClasses![index].init()
    }
    
    private func titleAtIndex(index: Int) -> String {
        if let titleAtIndex = dataSource?.pageController?(self, titleAtIndex: index) {
            return titleAtIndex
        }
        return titles![index]
    }
    
    // MARK: - Delegate
    private func infoWithIndex(index: Int) -> NSDictionary {
        let title = titleAtIndex(index)
        return ["title": title, "index": index]
    }
    
    private func willCachedController(vc: UIViewController, atIndex index: Int) {
        guard childControllersCount > 0 else { return }
        delegate?.pageController?(self, willCachedViewController: vc, withInfo: infoWithIndex(index))
    }
    
    private func willEnterController(vc: UIViewController, atIndex index: Int) {
        guard childControllersCount > 0 else { return }
        delegate?.pageController?(self, willEnterViewController: vc, withInfo: infoWithIndex(index))
    }
    
    private func didEnterController(vc: UIViewController, atIndex index: Int) {
       
        guard childControllersCount > 0 else { return }
        
        let info = infoWithIndex(index)

        delegate?.pageController?(self, didEnterViewController: vc, withInfo: info)
        
        if initializedIndex == index {
            delegate?.pageController?(self, lazyLoadViewController: vc, withInfo: info)
            initializedIndex = -1
        }
        
        if preloadPolicy == .Never { return }
        var start = 0
        var end = childControllersCount - 1
        if index > preloadPolicy.rawValue {
            start = index - preloadPolicy.rawValue
        }
        
        if childControllersCount - 1 > preloadPolicy.rawValue + index {
            end = index + preloadPolicy.rawValue
        }
        
        for i in start ... end {
            if memCache.objectForKey(i) == nil && displayingControllers[i] == nil {
                addViewControllerAtIndex(i)
                postMovedToSuperViewNotificationWithIndex(i)
            }
        }
        _selectedIndex = index
    }
    
    // MARK: - Private funcs
    private func clearDatas() {
        controllerCount = -1
        hasInit = false
        _selectedIndex = _selectedIndex < childControllersCount ? _selectedIndex : childControllersCount - 1
        for viewController in displayingControllers.allValues {
            if let vc = viewController as? UIViewController {
                vc.view.removeFromSuperview()
                vc.willMoveToParentViewController(nil)
                vc.removeFromParentViewController()
            }
        }
        memoryWarningCount = 0
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(PageController.growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(PageController.growCachePolicyToHigh), object: nil)
        currentViewController = nil
        displayingControllers.removeAllObjects()
        calculateSize()
    }
    
    private func resetScrollView() {
        contentView?.removeFromSuperview()
        addScrollView()
        addViewControllerAtIndex(_selectedIndex)
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
    }
    
    private func calculateSize() {
        var navBarHeight = (navigationController != nil) ? CGRectGetMaxY(navigationController!.navigationBar.frame) : 0
        let tabBar = tabBarController?.tabBar ?? (navigationController?.toolbar ?? nil)
        let height = (tabBar != nil && tabBar?.hidden != true) ? CGRectGetHeight(tabBar!.frame) : 0
        var tabBarHeight = (hidesBottomBarWhenPushed == true) ? 0 : height
        
        let mainWindow = UIApplication.sharedApplication().delegate?.window!
        let absoluteRect = view.superview?.convertRect(view.frame, toView: mainWindow)
        if let rect = absoluteRect {
            navBarHeight -= rect.origin.y;
            tabBarHeight -= mainWindow!.frame.height - CGRectGetMaxY(rect);
        }
        
        viewX = viewFrame.origin.x
        viewY = viewFrame.origin.y
        if viewFrame == CGRectZero {
            viewWidth  = view.frame.size.width
            viewHeight = view.frame.size.height - menuHeight - navBarHeight - tabBarHeight
            viewY += navBarHeight
        } else {
            viewWidth = viewFrame.size.width
            viewHeight = viewFrame.size.height - menuHeight
        }
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            viewHeight += menuHeight
        }
        childViewFrames.removeAll()
        for index in 0 ..< childControllersCount {
            let viewControllerFrame = CGRect(x: CGFloat(index) * viewWidth, y: 0, width: viewWidth, height: viewHeight)
            childViewFrames.append(viewControllerFrame)
        }
    }
    
    private func addScrollView() {
        let scrollView = ContentView()
        scrollView.scrollsToTop = false
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = bounces
        view.addSubview(scrollView)
        contentView = scrollView
    }
    
    private func addMenuView() {
        var menuY = viewY
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            let naviHeight = CGRectGetHeight(navigationController!.navigationBar.frame)
            let realMenuHeight = menuHeight > naviHeight ? naviHeight : menuHeight
            menuY = (naviHeight - realMenuHeight) / 2
        }
        
        let menuViewFrame = CGRect(x: viewX, y: menuY, width: viewWidth, height: menuHeight)
        let menu = MenuView(frame: menuViewFrame)
        menu.delegate = self
        menu.dataSource = self
        menu.backgroundColor = menuBGColor
        menu.normalSize = titleSizeNormal
        menu.selectedSize = titleSizeSelected
        menu.normalColor = titleColorNormal
        menu.selectedColor = titleColorSelected
        menu.style = menuViewStyle
        menu.progressHeight = progressHeight
        menu.progressColor = progressColor
        menu.fontName = titleFontName
        menu.contentMargin = menuViewContentMargin
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            navigationItem.titleView = menu
        } else {
            view.addSubview(menu)
        }
        menuView = menu
    }
    
    private func postMovedToSuperViewNotificationWithIndex(index: Int) {
        guard postNotification else { return }
        let info = ["index": index, "title": titleAtIndex(index)]
        NSNotificationCenter.defaultCenter().postNotificationName(WMPageControllerDidMovedToSuperViewNotification, object: info)
    }
    
    private func postFullyDisplayedNotificationWithIndex(index: Int) {
        guard postNotification else { return }
        let info = ["index": index, "title": titleAtIndex(index)]
        NSNotificationCenter.defaultCenter().postNotificationName(WMPageControllerDidFullyDisplayedNotification, object: info)
    }
    
    private func layoutChildViewControllers() {
        let currentPage = Int(contentView!.contentOffset.x / viewWidth)
        let start = currentPage == 0 ? currentPage : (currentPage - 1)
        let end = (currentPage == childControllersCount - 1) ? currentPage : (currentPage + 1)
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
    
    private func removeSuperfluousViewControllersIfNeeded() {
        self.displayingControllers.enumerateKeysAndObjectsUsingBlock { [weak self] (index, vc, stop) -> Void in
            guard let strongSelf = self else { return }
            let frame = strongSelf.childViewFrames[index.integerValue]
            if (strongSelf.inScreen(frame) == false) {
                strongSelf.removeViewController(vc as! UIViewController, atIndex: index.integerValue)
            }
        }
    }
    
    private func addCachedViewController(viewController: UIViewController, atIndex index: Int) {
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames[index]
        viewController.didMoveToParentViewController(self)
        contentView?.addSubview(viewController.view)
        willEnterController(viewController, atIndex: index)
        displayingControllers.setObject(viewController, forKey: index)
    }
    
    private func addViewControllerAtIndex(index: Int) {
        initializedIndex = index
        let viewController = initializeViewControllerAtIndex(index)
        if let optionalKeys = keys {
            viewController.setValue(values?[index], forKey: optionalKeys[index])
        }
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames.count > 0 ? childViewFrames[index] : view.frame
        viewController.didMoveToParentViewController(self)
        contentView?.addSubview(viewController.view)
        willEnterController(viewController, atIndex: index)
        displayingControllers.setObject(viewController, forKey: index)
    }
    
    private func removeViewController(viewController: UIViewController, atIndex index: Int) {
        viewController.view.removeFromSuperview()
        viewController.willMoveToParentViewController(nil)
        viewController.removeFromParentViewController()
        displayingControllers.removeObjectForKey(index)
        if memCache.objectForKey(index) == nil {
            willCachedController(viewController, atIndex: index)
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
        if menuView == nil {
            addMenuView()
            return
        }
        menuView?.reload()
        guard selectedIndex != 0 else { return }
        menuView?.selectItemAtIndex(selectedIndex)
        view.bringSubviewToFront(menuView!)
    }
    
    @objc private func growCachePolicyAfterMemoryWarning() {
        cachePolicy = CachePolicy.Balanced
        performSelector(#selector(PageController.growCachePolicyToHigh), withObject: nil, afterDelay: 2.0, inModes: [NSRunLoopCommonModes])
    }
    
    @objc private func growCachePolicyToHigh() {
        cachePolicy = CachePolicy.High
    }
    
    // MARK: - Adjust Frame
    private func adjustScrollViewFrame() {
        shouldNotScroll = true
        var scrollFrame = CGRect(x: viewX, y: viewY + menuHeight, width: viewWidth, height: viewHeight)
        scrollFrame.origin.y -= showOnNavigationBar && (navigationController?.navigationBar != nil) ? menuHeight : 0
        contentView?.frame = scrollFrame
        contentView?.contentSize = CGSize(width: CGFloat(childControllersCount) * viewWidth, height: 0)
        contentView?.contentOffset = CGPoint(x: CGFloat(_selectedIndex) * viewWidth, y: 0)
        shouldNotScroll = false
    }
    
    private func adjustMenuViewFrame() {
        var realMenuHeight = menuHeight
        var menuX = viewX
        var menuY = viewY
        
        var rightWidth: CGFloat = 0.0
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            for subview in (navigationController?.navigationBar.subviews)! {
                
                guard !subview.isKindOfClass(NSClassFromString("_UINavigationBarBackground")!) && !subview.isKindOfClass(MenuView.self) && (subview.alpha != 0) && (subview.hidden == false) else { continue }
                
                let maxX = CGRectGetMaxX(subview.frame)
                if maxX < viewWidth / 2 {
                    let leftWidth = maxX
                    menuX = menuX > leftWidth ? menuX : leftWidth
                }
                let minX = CGRectGetMinX(subview.frame)
                if minX > viewWidth / 2 {
                    let width = viewWidth - minX
                    rightWidth = rightWidth > width ? rightWidth : width
                }
                
            }
            let naviHeight = CGRectGetHeight(navigationController!.navigationBar.frame)
            realMenuHeight = menuHeight > naviHeight ? naviHeight : realMenuHeight
            menuY = (naviHeight - realMenuHeight) / 2
        }
        let menuWidth = viewWidth - menuX - rightWidth
        menuView?.frame = CGRect(x: menuX, y: menuY, width: menuWidth, height: realMenuHeight)
        menuView?.resetFrames()
        
        if _selectedIndex != 0 {
            menuView?.selectItemAtIndex(_selectedIndex)
        }
    }
    
    // MARK: - UIScrollView Delegate
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if shouldNotScroll || !hasInit { return }
        
        layoutChildViewControllers()
        guard startDragging else { return }
        var contentOffsetX = contentView!.contentOffset.x
        if contentOffsetX < 0.0 {
            contentOffsetX = 0.0
        }
        if contentOffsetX > (scrollView.contentSize.width - viewWidth) {
            contentOffsetX = scrollView.contentSize.width - viewWidth
        }
        let rate = contentOffsetX / viewWidth
        menuView?.slideMenuAtProgress(rate)
        
        if scrollView.contentOffset.y == 0 { return }
        var contentOffset = scrollView.contentOffset
        contentOffset.y = 0.0
        scrollView.contentOffset = contentOffset
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        startDragging = true
        menuView?.userInteractionEnabled = false
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        menuView?.userInteractionEnabled = true
        _selectedIndex = Int(contentView!.contentOffset.x / viewWidth)
        removeSuperfluousViewControllersIfNeeded()
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        _selectedIndex = Int(contentView!.contentOffset.x / viewWidth)
        removeSuperfluousViewControllersIfNeeded()
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        menuView?.userInteractionEnabled = true
        let rate = targetX / viewWidth
        menuView?.slideMenuAtProgress(rate)
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetX = targetContentOffset.memory.x
    }
    
    // MARK: - MenuViewDelegate
    public func menuView(menuView: MenuView, didSelectedIndex index: Int, fromIndex currentIndex: Int) {
        guard hasInit else { return }
        startDragging = false
        let targetPoint = CGPoint(x: CGFloat(index) * viewWidth, y: 0)
        contentView?.setContentOffset(targetPoint, animated: pageAnimatable)
        if !pageAnimatable {
            removeSuperfluousViewControllersIfNeeded()
            if let viewController = displayingControllers[index] as? UIViewController {
                removeViewController(viewController, atIndex: index)
            }
            layoutChildViewControllers()
            currentViewController = displayingControllers[index] as? UIViewController
            postFullyDisplayedNotificationWithIndex(index)
            _selectedIndex = index
            didEnterController(currentViewController!, atIndex: _selectedIndex)
        }
    }
    
    public func menuView(menuView: MenuView, widthForItemAtIndex index: Int) -> CGFloat {
        if let widths = itemsWidths {
            return widths[index]
        }
        return menuItemWidth
    }
    
    public func menuView(menuView: MenuView, itemMarginAtIndex index: Int) -> CGFloat {
        if let margins = itemsMargins {
            return margins[index]
        }
        return itemMargin
    }
    
    // MARK: - MenuViewDataSource
    public func numbersOfTitlesInMenuView(menuView: MenuView) -> Int {
        return childControllersCount
    }
    
    public func menuView(menuView: MenuView, titleAtIndex index: Int) -> String {
        return titleAtIndex(index)
    }
    
}
