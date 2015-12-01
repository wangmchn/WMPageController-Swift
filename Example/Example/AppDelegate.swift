//
//  AppDelegate.swift
//  Example
//
//  Created by Mark on 15/12/1.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let pageController = customedPageController()
        window?.rootViewController = UINavigationController(rootViewController: pageController)
//        reloadPageController(pageController, afterDelay: 5.0)
//        updatePageController(pageController, title: "hahahahaha", afterDelay: 5.0)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - An example of `PageController`
    private func customedPageController() -> PageController {
        let vcClasses: [UIViewController.Type] = [ViewController.self, TableViewController.self]
        let titles = ["Hello", "World"]
        let pageController = PageController(vcClasses: vcClasses, theirTitles: titles)
        pageController.pageAnimatable = true
        pageController.menuViewStyle = MenuViewStyle.Line
        pageController.bounces = true
        pageController.menuHeight = 35.0
        pageController.titleSizeSelected = 15
        pageController.values = ["Hello", "I'm Mark"] // pass values
        pageController.keys = ["type", "text"] // keys
        pageController.title = "Test"
        pageController.menuBGColor = .whiteColor()
        //        pageController.selectedIndex = 1
        //        pageController.progressColor = .blackColor()
        //        pageController.viewFrame = CGRect(x: 50, y: 100, width: 320, height: 500)
        //        pageController.itemsWidths = [100, 50]
        //        pageController.itemsMargins = [50, 10, 100]
        //        pageController.titleSizeNormal = 12
        //        pageController.titleSizeSelected = 14
        //        pageController.titleColorNormal = UIColor.brownColor()
        //        pageController.titleColorSelected = UIColor.blackColor()
        return pageController
    }

    private func reloadPageController(pageController: PageController, afterDelay delay: NSTimeInterval) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            pageController.titles = ["Hello", "World", "Reload"]
            pageController.viewControllerClasses = [ViewController.self, TableViewController.self, ViewController.self]
            pageController.values = ["Hello", "I'm Mark", "Reload"]
            pageController.keys = ["type", "text", "type"]
            pageController.reloadData()
        }
    }
    
    private func updatePageController(pageController: PageController, title: String, afterDelay delay: NSTimeInterval) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            pageController.updateTitle(title, atIndex: 1, andWidth: 150)
        }
    }
    
}

