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
        view.backgroundColor = .white
        createLabel()
    }
    
    fileprivate func createLabel() {
        let label = UILabel(frame: CGRect(x: 0, y: 100, width: view.bounds.size.width, height: 100))
        label.text = type
        label.font = UIFont.systemFont(ofSize: 22)
        label.textAlignment = .center
        view.addSubview(label)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

