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
        itemsWidths = [60, 100, 60]
        dataSource = self
        delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
    
}
