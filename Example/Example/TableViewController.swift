//
//  TableViewController.swift
//  PageController
//
//  Created by Mark on 15/10/31.
//  Copyright © 2015年 Wecan Studio. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var text = ""
    private let cellReuseIdentifier = "cellReuseIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.rowHeight = 60
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
 
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.imageView?.image = UIImage(named: "github")
        cell.textLabel?.text = text

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let vc = ViewController()
        let vc = customedPageController()
        vc.title = "Push"
//        vc.type = "Bye bye"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - An example of `PageController`
    private func customedPageController() -> PageController {
        let vcClasses: [UIViewController.Type] = [ViewController.self, TableViewController.self]
        let titles = ["Hello", "World"]
        let pageController = PageController(vcClasses: vcClasses, theirTitles: titles)
        pageController.pageAnimatable = true
        pageController.menuViewStyle = MenuViewStyle.Line
        pageController.bounces = true
        pageController.menuHeight = 44
        pageController.titleSizeSelected = 15
        pageController.values = ["Hello", "I'm Mark"] // pass values
        pageController.keys = ["type", "text"] // keys
        pageController.title = "Test"
        pageController.menuBGColor = .clearColor()
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
    
}
