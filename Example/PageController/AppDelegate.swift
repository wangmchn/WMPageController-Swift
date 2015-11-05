//
//  AppDelegate.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let vcClasses: [UIViewController.Type] = [ViewController.self, TableViewController.self]
        let titles = ["试试", "成功"]
        let pageController = PageController(vcClasses: vcClasses, theirTitles: titles)
        pageController.pageAnimatable = true
        pageController.menuViewStyle = MenuViewStyle.Line
        pageController.bounces = true
        pageController.menuHeight = 50.0
        pageController.values = ["Hello", "I'm Mark"]
        pageController.keys = ["type", "type"]
//        pageController.selectedIndex = 1
//        pageController.progressColor = .blackColor()
//        pageController.viewFrame = CGRect(x: 50, y: 100, width: 320, height: 500)
//        pageController.itemsWidths = [100, 50]
//        pageController.itemsMargins = [50, 10, 100]
//        pageController.titleSizeNormal = 12
//        pageController.titleSizeSelected = 14
//        pageController.titleColorNormal = UIColor.brownColor()
//        pageController.titleColorSelected = UIColor.blackColor()
        
        let navigationController = UINavigationController(rootViewController: pageController)
        pageController.title = "Test"
        window?.rootViewController = navigationController
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


}

