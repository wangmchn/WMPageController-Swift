//
//  ViewController.swift
//  PageController
//
//  Created by Mark on 15/10/20.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate {

    var type = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("viewDidLoad \(self)")
        print(type)
        view.backgroundColor = .redColor()
    }
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        print("viewWillAppear \(self)")
//    }
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        print("viewDidAppear \(self)")
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

