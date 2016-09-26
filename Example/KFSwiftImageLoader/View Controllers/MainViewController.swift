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
        let url = NSURL(string: "https://api.duckduckgo.com/?q=simpsons+characters&format=json")!
        let request = NSURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60.0)
        
        let dataTask = session.dataTaskWithRequest(request) {
            (taskData, taskResponse, taskError) in
            
            guard let data = taskData where taskError == nil else {
                print("Error retrieving response from the DuckDuckGo API.")
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                do {
                    if let jsonDict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String: AnyObject] {
                        if let relatedTopics = jsonDict["RelatedTopics"] as? [[String: AnyObject]] {
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
                catch {
                    print("Error when parsing the response JSON: \(error)")
                }
            }
        }
        
        dataTask.resume()
    }
    
    func randomizeImages() {
        for (var i = 0; i < self.imageURLStringsArray.count; i++) {
            let randomIndex = Int(arc4random()) % self.imageURLStringsArray.count
            let randomImageURLString = self.imageURLStringsArray[randomIndex]
            self.imageURLStringsArray[randomIndex] = self.imageURLStringsArray[i]
            self.imageURLStringsArray[i] = randomImageURLString
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
            
            cell.featuredImageView.loadImageFromURLString(self.imageURLStringsArray[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali")) {
                (finished, potentialError) in
                
                if finished {
                    // Do something in the completion block.
                }
                else if let error = potentialError {
                    print("error occurred with description: \(error.localizedDescription)")
                }
            }
            
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
