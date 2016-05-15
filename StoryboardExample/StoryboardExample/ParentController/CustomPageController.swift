//
//  CustomPageController.swift
//  StoryboardExample
//
//  Created by Mark on 16/1/4.
//  Copyright © 2016年 Wecan Studio. All rights reserved.
//

import UIKit

class CustomPageController: PageController {

    var vcTitles = ["use", "storyboard", "xib"]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        dataSource = self
        delegate = self
        preloadPolicy = PreloadPolicy.Neighbour
        menuViewContentMargin = 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        menuView?.leftView = customButtonWithTitle("Left")
        menuView?.rightView = customButtonWithTitle("Right")
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5.0 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.vcTitles = ["Test", "Test", "Test", "Test", "Test", "Test"]
            self.reloadData()
        }
    }

    private func customButtonWithTitle(title: String) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: menuHeight))
        button.addTarget(self, action: #selector(CustomPageController.buttonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.setTitle(title, forState: UIControlState.Normal)
        button.setTitleColor(.blueColor(), forState: UIControlState.Normal)
        return button
    }
    
    @objc private func buttonPressed(sender: UIButton) {
        print(sender)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - PageController DataSource
    func numberOfControllersInPageController(pageController: PageController) -> Int {
        return vcTitles.count
    }
    
    func pageController(pageController: PageController, titleAtIndex index: Int) -> String {
        return vcTitles[index]
    }
    
    func pageController(pageController: PageController, viewControllerAtIndex index: Int) -> UIViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        switch index {
            case 0: return sb.instantiateViewControllerWithIdentifier("ViewController")
            case 1: return sb.instantiateViewControllerWithIdentifier("TableViewController")
            default: return UIViewController()
        }
    }
    
    func pageController(pageController: PageController, lazyLoadViewController viewController: UIViewController, withInfo info: NSDictionary) {
        print(info)
    }
    
    override func menuView(menuView: MenuView, widthForItemAtIndex index: Int) -> CGFloat {
        if index == 1 {
            return 100
        }
        return 60
    }
    
}
