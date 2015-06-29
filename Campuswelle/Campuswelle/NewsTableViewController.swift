//
//  NewsTableViewController.swift
//  Campuswelle
//
//  Created by Valentin Knabel on 20.05.15.
//  Copyright (c) 2015 Valentin Knabel. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController, SegueHandlerType {

    var news: [News] = []
    
    func tryReload() {
        fetchNews(success: { (n) -> () in
            self.news = n
            self.tableView.reloadData()
            print("NewsTableViewController.tryReload: news reloaded")
            
            }) { (error) -> () in
                print("NewsTableViewController.tryReload: \(error)")
                delay(5) {
                    self.tryReload()
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tryReload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return news.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("newsCell", forIndexPath: indexPath) as UITableViewCell
        
        // Configure the cell...
        cell.textLabel?.text = news[indexPath.row].article.title
        cell.detailTextLabel?.text = news[indexPath.row].article.desc
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
    
    enum SegueIdentifier: String {
        case PlayLiveSegue = "PlayLiveSegue"
        case ShowArticleSegue = "ShowArticleSegue"
        case ShowPlaybackSegue = "ShowPlaybackSegue"
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        switch segueIdentifierForSegue(segue) {
        case .PlayLiveSegue:
            guard let playbackController = segue.destinationViewController as? PlaybackViewController
                else { fatalError("segue not possible") }
            guard case .LiveStreamItem = playbackController.currentItem else {
                playbackController.currentItem = .LiveStreamItem
                break
            }
        case .ShowPlaybackSegue:
            break
        case .ShowArticleSegue:
            guard let newsViewController = segue.destinationViewController as? NewsViewController
                else { fatalError("segue not possible") }
            newsViewController.news = news[tableView.indexPathForSelectedRow!.row]
        }
    }

}
