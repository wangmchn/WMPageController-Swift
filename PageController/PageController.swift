//
//  PageController.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

public enum CachePolicy: Int {
    case noLimit    = 0
    case lowMemory  = 1
    case balanced   = 3
    case high       = 5
}

public enum PreloadPolicy: Int {
    case never      = 0
    case neighbour  = 1
    case near       = 2
}

public let WMPageControllerDidMovedToSuperViewNotification = "WMPageControllerDidMovedToSuperViewNotification"
public let WMPageControllerDidFullyDisplayedNotification = "WMPageControllerDidFullyDisplayedNotification"

@objc public protocol PageControllerDataSource: NSObjectProtocol {
    @objc optional func numberOfControllersInPageController(_ pageController: PageController) -> Int
    @objc optional func pageController(_ pageController: PageController, viewControllerAtIndex index: Int) -> UIViewController
    @objc optional func pageController(_ pageController: PageController, titleAtIndex index: Int) -> String
}

@objc public protocol PageControllerDelegate: NSObjectProtocol {
    @objc optional func pageController(_ pageController: PageController, lazyLoadViewController viewController: UIViewController, withInfo info: NSDictionary)
    @objc optional func pageController(_ pageController: PageController, willCachedViewController viewController: UIViewController, withInfo info: NSDictionary)
    @objc optional func pageController(_ pageController: PageController, willEnterViewController viewController: UIViewController, withInfo info: NSDictionary)
    @objc optional func pageController(_ pageController: PageController, didEnterViewController viewController: UIViewController, withInfo info: NSDictionary)
}

open class ContentView: UIScrollView, UIGestureRecognizerDelegate {
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let wrapperView = NSClassFromString("UITableViewWrapperView"), let otherGestureView = otherGestureRecognizer.view else { return false }
        
        if otherGestureView.isKind(of: wrapperView) && (otherGestureRecognizer is UIPanGestureRecognizer) {
            return true
        }
        return false
    }
    
}

open class PageController: UIViewController, UIScrollViewDelegate, MenuViewDelegate, MenuViewDataSource, PageControllerDelegate, PageControllerDataSource {
    
    // MARK: - Public vars
    open weak var dataSource: PageControllerDataSource?
    open weak var delegate: PageControllerDelegate?
    
    open var viewControllerClasses: [UIViewController.Type]?
    open var titles: [String]?
    open var values: NSArray?
    open var keys: [String]?
    open var progressColor: UIColor?
    open var progressHeight: CGFloat = 2.0
    open var itemMargin: CGFloat = 0.0
    open var menuViewStyle = MenuViewStyle.default
    open var titleFontName: String?
    open var pageAnimatable   = false
    open var postNotification = false
    open var bounces = false
    open var showOnNavigationBar = false
    open var startDragging = false
    open var titleSizeSelected: CGFloat  = 18.0
    open var titleSizeNormal: CGFloat    = 15.0
    open var menuHeight: CGFloat         = 30.0
    open var menuItemWidth: CGFloat      = 65.0
    open weak var contentView: ContentView?
    open weak var menuView: MenuView?

    open var itemsWidths: [CGFloat]?
    
    open fileprivate(set) var currentViewController: UIViewController?
    
    open var selectedIndex: Int {
        set {
            _selectedIndex = newValue
            menuView?.selectItemAtIndex(newValue)
        }
        get { return _selectedIndex }
    }
    
    open var menuViewContentMargin: CGFloat = 0.0 {
        didSet {
            guard let menu = menuView else { return }
            menu.contentMargin = oldValue
        }
    }
    
    open var viewFrame = CGRect() {
        didSet {
            if let _ = menuView {
                hasInit = false
                viewDidLayoutSubviews()
            }
        }
    }
    
    open var itemsMargins: [CGFloat]?
    open var preloadPolicy: PreloadPolicy = .never
    
    open var cachePolicy: CachePolicy = .noLimit {
        didSet { memCache.countLimit = cachePolicy.rawValue }
    }
    
    open lazy var titleColorSelected = UIColor(red: 168.0/255.0, green: 20.0/255.0, blue: 4/255.0, alpha: 1.0)
    open lazy var titleColorNormal = UIColor.black
    open lazy var menuBGColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    
    override open var edgesForExtendedLayout: UIRectEdge {
        didSet {
            hasInit = false
            viewDidLayoutSubviews()
        }
    }
    
    // MARK: - Private vars
    fileprivate var memoryWarningCount = 0
    fileprivate var viewHeight: CGFloat = 0.0
    fileprivate var viewWidth: CGFloat = 0.0
    fileprivate var viewX: CGFloat = 0.0
    fileprivate var viewY: CGFloat = 0.0
    fileprivate var _selectedIndex = 0
    fileprivate var targetX: CGFloat = 0.0
    fileprivate var superviewHeight: CGFloat = 0.0
    fileprivate var hasInit = false
    fileprivate var shouldNotScroll = false
    fileprivate var initializedIndex = -1
    fileprivate var controllerCount  = -1
    
    fileprivate var childControllersCount: Int {
        if controllerCount == -1 {
            if let count = dataSource?.numberOfControllersInPageController?(self) {
                controllerCount = count
            } else {
                controllerCount = (viewControllerClasses?.count ?? 0)
            }
        }
        return controllerCount
    }
    
    lazy fileprivate var displayingControllers = NSMutableDictionary()
    lazy fileprivate var memCache = NSCache<NSNumber, UIViewController>()
    lazy fileprivate var childViewFrames = [CGRect]()
    
    // MARK: - Life cycle
    public convenience init(vcClasses: [UIViewController.Type], theirTitles: [String]) {
        self.init()
        assert(vcClasses.count == theirTitles.count, "`vcClasses.count` must equal to `titles.count`")
        titles = theirTitles
        viewControllerClasses = vcClasses
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        guard childControllersCount > 0 else { return }

        calculateSize()
        addScrollView()
        addViewControllerAtIndex(_selectedIndex)
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        addMenuView()
    }

    override open func viewDidLayoutSubviews() {
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
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard childControllersCount > 0 else { return }
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        memoryWarningCount += 1
        cachePolicy = CachePolicy.lowMemory
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(PageController.growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(PageController.growCachePolicyToHigh), object: nil)
        memCache.removeAllObjects()
        if memoryWarningCount < 3 {
            perform(#selector(PageController.growCachePolicyAfterMemoryWarning), with: nil, afterDelay: 3.0, inModes: [RunLoopMode.commonModes])
        }
    }
    
    // MARK: - Reload
    open func reloadData() {
        clearDatas()
        resetScrollView()
        memCache.removeAllObjects()
        viewDidLayoutSubviews()
        resetMenuView()
    }
    
    // MARK: - Update Title
    open func updateTitle(_ title: String, atIndex index: Int) {
        menuView?.updateTitle(title, atIndex: index, andWidth: false)
    }
    
    open func updateTitle(_ title: String, atIndex index: Int, andWidth width: CGFloat) {
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
    fileprivate func initializeViewControllerAtIndex(_ index: Int) -> UIViewController {
        if let viewController = dataSource?.pageController?(self, viewControllerAtIndex: index) {
            return viewController
        }
        return viewControllerClasses![index].init()
    }
    
    fileprivate func titleAtIndex(_ index: Int) -> String {
        if let titleAtIndex = dataSource?.pageController?(self, titleAtIndex: index) {
            return titleAtIndex
        }
        return titles![index]
    }
    
    // MARK: - Delegate
    fileprivate func infoWithIndex(_ index: Int) -> NSDictionary {
        let title = titleAtIndex(index)
        return ["title": title, "index": index]
    }
    
    fileprivate func willCachedController(_ vc: UIViewController, atIndex index: Int) {
        guard childControllersCount > 0 else { return }
        delegate?.pageController?(self, willCachedViewController: vc, withInfo: infoWithIndex(index))
    }
    
    fileprivate func willEnterController(_ vc: UIViewController, atIndex index: Int) {
        guard childControllersCount > 0 else { return }
        delegate?.pageController?(self, willEnterViewController: vc, withInfo: infoWithIndex(index))
    }
    
    fileprivate func didEnterController(_ vc: UIViewController, atIndex index: Int) {
       
        guard childControllersCount > 0 else { return }
        
        let info = infoWithIndex(index)

        delegate?.pageController?(self, didEnterViewController: vc, withInfo: info)
        
        if initializedIndex == index {
            delegate?.pageController?(self, lazyLoadViewController: vc, withInfo: info)
            initializedIndex = -1
        }
        
        if preloadPolicy == .never { return }
        var start = 0
        var end = childControllersCount - 1
        if index > preloadPolicy.rawValue {
            start = index - preloadPolicy.rawValue
        }
        
        if childControllersCount - 1 > preloadPolicy.rawValue + index {
            end = index + preloadPolicy.rawValue
        }
        
        for i in start ... end {
            if memCache.object(forKey: NSNumber(integerLiteral: i)) == nil && displayingControllers[i] == nil {
                addViewControllerAtIndex(i)
                postMovedToSuperViewNotificationWithIndex(i)
            }
        }
        _selectedIndex = index
    }
    
    // MARK: - Private funcs
    fileprivate func clearDatas() {
        controllerCount = -1
        hasInit = false
        _selectedIndex = _selectedIndex < childControllersCount ? _selectedIndex : childControllersCount - 1
        for viewController in displayingControllers.allValues {
            if let vc = viewController as? UIViewController {
                vc.view.removeFromSuperview()
                vc.willMove(toParentViewController: nil)
                vc.removeFromParentViewController()
            }
        }
        memoryWarningCount = 0
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(PageController.growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(PageController.growCachePolicyToHigh), object: nil)
        currentViewController = nil
        displayingControllers.removeAllObjects()
        calculateSize()
    }
    
    fileprivate func resetScrollView() {
        contentView?.removeFromSuperview()
        addScrollView()
        addViewControllerAtIndex(_selectedIndex)
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
    }
    
    fileprivate func calculateSize() {
        var navBarHeight = (navigationController != nil) ? navigationController!.navigationBar.frame.maxY : 0
        let tabBar = tabBarController?.tabBar ?? (navigationController?.toolbar ?? nil)
        let height = (tabBar != nil && tabBar?.isHidden != true) ? tabBar!.frame.height : 0
        var tabBarHeight = (hidesBottomBarWhenPushed == true) ? 0 : height
        
        let mainWindow = UIApplication.shared.delegate?.window!
        let absoluteRect = view.superview?.convert(view.frame, to: mainWindow)
        if let rect = absoluteRect {
            navBarHeight -= rect.origin.y;
            tabBarHeight -= mainWindow!.frame.height - rect.maxY;
        }
        
        viewX = viewFrame.origin.x
        viewY = viewFrame.origin.y
        if viewFrame == CGRect.zero {
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
    
    fileprivate func addScrollView() {
        let scrollView = ContentView()
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = bounces
        view.addSubview(scrollView)
        contentView = scrollView
    }
    
    fileprivate func addMenuView() {
        var menuY = viewY
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            let naviHeight = navigationController!.navigationBar.frame.height
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
    
    fileprivate func postMovedToSuperViewNotificationWithIndex(_ index: Int) {
        guard postNotification else { return }
        let info = ["index": index, "title": titleAtIndex(index)] as [String : Any]
        NotificationCenter.default.post(name: Notification.Name(rawValue: WMPageControllerDidMovedToSuperViewNotification), object: info)
    }
    
    fileprivate func postFullyDisplayedNotificationWithIndex(_ index: Int) {
        guard postNotification else { return }
        let info = ["index": index, "title": titleAtIndex(index)] as [String : Any]
        NotificationCenter.default.post(name: Notification.Name(rawValue: WMPageControllerDidFullyDisplayedNotification), object: info)
    }
    
    fileprivate func layoutChildViewControllers() {
        let currentPage = Int(contentView!.contentOffset.x / viewWidth)
        let start = currentPage == 0 ? currentPage : (currentPage - 1)
        let end = (currentPage == childControllersCount - 1) ? currentPage : (currentPage + 1)
        for index in start ... end {
            let viewControllerFrame = childViewFrames[index]
            var vc = displayingControllers.object(forKey: index)
            if inScreen(viewControllerFrame) {
                if vc == nil {
                    vc = memCache.object(forKey: NSNumber(integerLiteral: index))
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
    
    fileprivate func removeSuperfluousViewControllersIfNeeded() {
        for (index, vc) in displayingControllers {
            
            let frame = childViewFrames[(index as AnyObject).intValue]
            if (inScreen(frame) == false) {
                removeViewController(vc as! UIViewController, atIndex: (index as AnyObject).intValue)
            }
        }
    }
    
    fileprivate func addCachedViewController(_ viewController: UIViewController, atIndex index: Int) {
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames[index]
        viewController.didMove(toParentViewController: self)
        contentView?.addSubview(viewController.view)
        willEnterController(viewController, atIndex: index)
        displayingControllers.setObject(viewController, forKey: index as NSCopying)
    }
    
    fileprivate func addViewControllerAtIndex(_ index: Int) {
        initializedIndex = index
        let viewController = initializeViewControllerAtIndex(index)
        if let optionalKeys = keys {
            viewController.setValue(values?[index], forKey: optionalKeys[index])
        }
        addChildViewController(viewController)
        viewController.view.frame = childViewFrames.count > 0 ? childViewFrames[index] : view.frame
        viewController.didMove(toParentViewController: self)
        contentView?.addSubview(viewController.view)
        willEnterController(viewController, atIndex: index)
        displayingControllers.setObject(viewController, forKey: index as NSCopying)
    }
    
    fileprivate func removeViewController(_ viewController: UIViewController, atIndex index: Int) {
        viewController.view.removeFromSuperview()
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        displayingControllers.removeObject(forKey: index)
        if memCache.object(forKey: NSNumber(integerLiteral: index)) == nil {
            willCachedController(viewController, atIndex: index)
            memCache.setObject(viewController, forKey: NSNumber(integerLiteral: index))
        }
    }
    
    fileprivate func inScreen(_ frame: CGRect) -> Bool {
        let x = frame.origin.x
        let ScreenWidth = contentView!.frame.size.width
        let contentOffsetX = contentView!.contentOffset.x
        if (frame.maxX > contentOffsetX) && (x - contentOffsetX < ScreenWidth) {
            return true
        }
        return false
    }
    
    fileprivate func resetMenuView() {
        if menuView == nil {
            addMenuView()
            return
        }
        menuView?.reload()
        guard selectedIndex != 0 else { return }
        menuView?.selectItemAtIndex(selectedIndex)
        view.bringSubview(toFront: menuView!)
    }
    
    @objc fileprivate func growCachePolicyAfterMemoryWarning() {
        cachePolicy = CachePolicy.balanced
        perform(#selector(PageController.growCachePolicyToHigh), with: nil, afterDelay: 2.0, inModes: [RunLoopMode.commonModes])
    }
    
    @objc fileprivate func growCachePolicyToHigh() {
        cachePolicy = CachePolicy.high
    }
    
    // MARK: - Adjust Frame
    fileprivate func adjustScrollViewFrame() {
        shouldNotScroll = true
        var scrollFrame = CGRect(x: viewX, y: viewY + menuHeight, width: viewWidth, height: viewHeight)
        scrollFrame.origin.y -= showOnNavigationBar && (navigationController?.navigationBar != nil) ? menuHeight : 0
        contentView?.frame = scrollFrame
        contentView?.contentSize = CGSize(width: CGFloat(childControllersCount) * viewWidth, height: 0)
        contentView?.contentOffset = CGPoint(x: CGFloat(_selectedIndex) * viewWidth, y: 0)
        shouldNotScroll = false
    }
    
    fileprivate func adjustMenuViewFrame() {
        var realMenuHeight = menuHeight
        var menuX = viewX
        var menuY = viewY
        
        var rightWidth: CGFloat = 0.0
        if showOnNavigationBar && (navigationController?.navigationBar != nil) {
            for subview in (navigationController?.navigationBar.subviews)! {
                guard let UINavigationBarBackgroundClass = NSClassFromString("_UINavigationBarBackground") else {
                    continue
                }
                
                guard !subview.isKind(of: UINavigationBarBackgroundClass) && !subview.isKind(of: MenuView.self) && (subview.alpha != 0) && (subview.isHidden == false) else { continue }
                
                let maxX = subview.frame.maxX
                if maxX < viewWidth / 2 {
                    let leftWidth = maxX
                    menuX = menuX > leftWidth ? menuX : leftWidth
                }
                let minX = subview.frame.minX
                if minX > viewWidth / 2 {
                    let width = viewWidth - minX
                    rightWidth = rightWidth > width ? rightWidth : width
                }
                
            }
            let naviHeight = navigationController!.navigationBar.frame.height
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
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startDragging = true
        menuView?.isUserInteractionEnabled = false
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        menuView?.isUserInteractionEnabled = true
        _selectedIndex = Int(contentView!.contentOffset.x / viewWidth)
        removeSuperfluousViewControllersIfNeeded()
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _selectedIndex = Int(contentView!.contentOffset.x / viewWidth)
        removeSuperfluousViewControllersIfNeeded()
        currentViewController = displayingControllers[_selectedIndex] as? UIViewController
        postFullyDisplayedNotificationWithIndex(_selectedIndex)
        didEnterController(currentViewController!, atIndex: _selectedIndex)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        menuView?.isUserInteractionEnabled = true
        let rate = targetX / viewWidth
        menuView?.slideMenuAtProgress(rate)
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetX = targetContentOffset.pointee.x
    }
    
    // MARK: - MenuViewDelegate
    open func menuView(_ menuView: MenuView, didSelectedIndex index: Int, fromIndex currentIndex: Int) {
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
    
    open func menuView(_ menuView: MenuView, widthForItemAtIndex index: Int) -> CGFloat {
        if let widths = itemsWidths {
            return widths[index]
        }
        return menuItemWidth
    }
    
    open func menuView(_ menuView: MenuView, itemMarginAtIndex index: Int) -> CGFloat {
        if let margins = itemsMargins {
            return margins[index]
        }
        return itemMargin
    }
    
    // MARK: - MenuViewDataSource
    open func numbersOfTitlesInMenuView(_ menuView: MenuView) -> Int {
        return childControllersCount
    }
    
    open func menuView(_ menuView: MenuView, titleAtIndex index: Int) -> String {
        return titleAtIndex(index)
    }
    
}
