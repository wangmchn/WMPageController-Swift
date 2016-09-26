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


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let pageController = customedPageController()
        window?.rootViewController = UINavigationController(rootViewController: pageController)
//        reloadPageController(pageController, afterDelay: 5.0)
//        updatePageController(pageController, title: "hahahahaha", afterDelay: 5.0)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - An example of `PageController`
    fileprivate func customedPageController() -> PageController {
        let vcClasses: [UIViewController.Type] = [ViewController.self, TableViewController.self]
        let titles = ["Hello", "World"]
        let pageController = PageController(vcClasses: vcClasses, theirTitles: titles)
        pageController.pageAnimatable = true
        pageController.menuViewStyle = MenuViewStyle.line
        pageController.bounces = true
        pageController.menuHeight = 44
        pageController.titleSizeSelected = 15
        pageController.values = ["Hello", "I'm Mark"] // pass values
        pageController.keys = ["type", "text"] // keys
        pageController.title = "Test"
        pageController.menuBGColor = .clear
        pageController.showOnNavigationBar = true
        //        pageController.selectedIndex = 1
        //        pageController.progressColor = .blackColor()
        //        pageController.viewFrame = CGRect(x: 50, y: 100, width: 320, height: 500)
        //        pageController.itemsWidths = [100, 50]
        //        pageController.itemsMargins = [100, 10, 100]
        //        pageController.titleSizeNormal = 12
        //        pageController.titleSizeSelected = 14
        //        pageController.titleColorNormal = UIColor.brownColor()
        //        pageController.titleColorSelected = UIColor.blackColor()
        return pageController
    }

    fileprivate func reloadPageController(_ pageController: PageController, afterDelay delay: TimeInterval) {
        let delayTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            pageController.titles = ["Hello", "World", "Reload"]
            pageController.viewControllerClasses = [ViewController.self, TableViewController.self, ViewController.self]
            pageController.values = ["Hello", "I'm Mark", "Reload"]
            pageController.keys = ["type", "text", "type"]
            pageController.reloadData()
        }
    }
    
    fileprivate func updatePageController(_ pageController: PageController, title: String, afterDelay delay: TimeInterval) {
        let delayTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            pageController.updateTitle(title, atIndex: 1, andWidth: 150)
        }
    }
    
}

