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
        let session = URLSession.shared
        let url = URL(string: "https://api.duckduckgo.com/?q=simpsons+characters&format=json")!
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60.0)
        
        let dataTask = session.dataTask(with: request, completionHandler: {
            (taskData, taskResponse, taskError) in
            
            guard let data = taskData , taskError == nil else {
                print("Error retrieving response from the DuckDuckGo API.")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
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
                                // Comment to not randomize the image ordering.
                                self.randomizeImages()
                                
                                self.imagesTableView.reloadData()
                            }
                        }
                    }
                }
                catch {
                    print("Error when parsing the response JSON: \(error)")
                }
            }
        }) 
        
        dataTask.resume()
    }
    
    func randomizeImages() {
        for i in 0 ..< self.imageURLStringsArray.count {
            let randomIndex = Int(arc4random()) % self.imageURLStringsArray.count
            swap(&self.imageURLStringsArray[i], &self.imageURLStringsArray[randomIndex])
        }
    }
    
    // MARK: - Protocol Implementations
    // MARK: - UITableViewDataSource Protocol
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imageURLStringsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Even indices should contain imageview cells.
        if (indexPath as NSIndexPath).row % 2 == 0 {
            let cellIdentifier = "ImageTableViewCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ImageTableViewCell
            
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
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ButtonImageTableViewCell
            
            // Notice that the completion block can be ommitted, since it defaults to nil. The controlState and isBackgroundImage parameters can also be ommitted, as they default to .Normal and false, respectively.
            // Please read the documentation for more information.
            cell.featuredButtonView.loadImage(urlString: self.imageURLStringsArray[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali"), forState: .normal, isBackgroundImage: false)
            
            return cell
        }
    }
}
