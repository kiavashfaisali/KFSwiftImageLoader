//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit
import KFSwiftImageLoader

final class MainViewController: UIViewController, UITableViewDataSource {
    // MARK: - Properties
    @IBOutlet weak var imagesTableView: UITableView!
    
    var imageURLStringsArray = [String]()
    
    // MARK: - Memory Warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDuckDuckGoResults()
    }
    
    // MARK: - Miscellaneous Methods
    func loadDuckDuckGoResults() {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: "http://api.duckduckgo.com/?q=simpsons+characters&format=json")!
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60.0)

        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    var jsonError: NSError?
                    if let jsonDict = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as? [String: AnyObject] where jsonError == nil {
                        if let relatedTopics = jsonDict["RelatedTopics"] as? [[String: AnyObject]] {
                            self.imageURLStringsArray.removeAll(keepCapacity: false)
                            
                            for relatedTopic in relatedTopics {
                                if let imageURLString = relatedTopic["Icon"]?["URL"] as? String {
                                    if imageURLString != "" {
                                        for _ in 1...3 {
                                            self.imageURLStringsArray.append(imageURLString)
                                        }
                                    }
                                }
                            }
                            
                            if self.imageURLStringsArray.count > 0 {
                                // Uncomment to randomize the image ordering.
//                                self.randomizeImages()
                                
                                self.imagesTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        
        dataTask.resume()
    }
    
    func randomizeImages() {
        for (var i = 0; i < self.imageURLStringsArray.count; i++) {
            let randomIndex = Int(arc4random()) % self.imageURLStringsArray.count
            let tempValue = self.imageURLStringsArray[randomIndex]
            self.imageURLStringsArray[randomIndex] = self.imageURLStringsArray[i]
            self.imageURLStringsArray[i] = tempValue
        }
    }
    
    // MARK: - Protocol Implementations
    // MARK: - UITableViewDataSource Protocol
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imageURLStringsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Even indices should contain imageview cells.
        if indexPath.row % 2 == 0 {
            let cellIdentifier = "ImageTableViewCell"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ImageTableViewCell
            
            cell.featuredImageView.loadImageFromURLString(self.imageURLStringsArray[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali"), completion: nil)
            
            return cell
        }
        // Odd indices should contain button cells.
        else {
            let cellIdentifier = "ButtonImageTableViewCell"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ButtonImageTableViewCell
            
            // Notice that the completion block can be ommitted, since it defaults to nil. The controlState and isBackgroundImage parameters can also be ommitted, as they default to .Normal and false, respectively.
            // Please read the documentation for more information.
            cell.featuredButtonView.loadImageFromURLString(self.imageURLStringsArray[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali"), forState: .Normal, isBackgroundImage: false)
            
            return cell
        }
    }
}
