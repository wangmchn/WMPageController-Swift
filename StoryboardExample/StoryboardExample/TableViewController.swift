//
//  TableViewController.swift
//  StoryboardExample
//
//  Created by Mark on 16/1/4.
//  Copyright © 2016年 Wecan Studio. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    let reuseIdentifier = "reuseIdentifier"
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
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
        return 100
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = "This is a TableViewController from Storyboard"
        cell.textLabel?.font = UIFont.systemFontOfSize(15)
        return cell
    }

}
