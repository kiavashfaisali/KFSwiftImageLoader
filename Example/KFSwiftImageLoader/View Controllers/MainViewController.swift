//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit
import os
import KFSwiftImageLoader

final class MainViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var imagesTableView: UITableView!
    
    var imageURLStrings = [String]()
    
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
        let url = URL(string: "https://api.duckduckgo.com/?q=simpsons+characters&format=json")!
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60.0)
        
        let dataTask = URLSession.shared.dataTask(with: request) {
            (data, _, error) in
            
            guard let data = data, error == nil else {
                os_log("Error retrieving response from the DuckDuckGo API.", type: .error)
                return
            }
            
            DispatchQueue.main.async {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject],
                       let relatedTopics = jsonDict["RelatedTopics"] as? [[String: AnyObject]]
                    {
                        for relatedTopic in relatedTopics {
                            if let imageURLString = relatedTopic["Icon"]?["URL"] as? String, imageURLString != "" {
                                for _ in 1...3 {
                                    self.imageURLStrings.append(imageURLString)
                                }
                            }
                        }
                        
                        if self.imageURLStrings.count > 0 {
                            // Comment to not randomize the image ordering.
                            self.randomizeImages()
                            
                            self.imagesTableView.reloadData()
                        }
                    }
                }
                catch {
                    os_log("Error when parsing the response JSON: %{public}@", type: .error, error.localizedDescription)
                }
            }
        }
        
        dataTask.resume()
    }
    
    func randomizeImages() {
        for i in 0..<self.imageURLStrings.count {
            let randomIndex = Int(arc4random()) % self.imageURLStrings.count
            
            self.imageURLStrings.swapAt(i, randomIndex)
        }
    }
}

// MARK: - UITableViewDataSource Protocol
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imageURLStrings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Even indices should contain imageview cells.
        if (indexPath.row % 2) == 0 {
            let cellIdentifier = String(describing: ImageTableViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ImageTableViewCell
            
            cell.featuredImageView.loadImage(urlString: self.imageURLStrings[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali")) {
                (success, error) in
                
                guard error == nil else {
                    os_log("error occurred with description: %{public}@", type: .error, error!.localizedDescription)
                    return
                }
                
                if !success {
                    os_log("Image loader failed to finish because a URL object could not be formed from the provided URL String.", type: .error)
                }
            }
            
            return cell
        }
        // Odd indices should contain button cells.
        else {
            let cellIdentifier = String(describing: ButtonImageTableViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ButtonImageTableViewCell
            
            // Notice that the completion closure can be ommitted, since it defaults to nil. The `controlState` and `isBackgroundImage` parameters can also be ommitted, as they default to `.normal` and `false`, respectively.
            // Please read the documentation for more information.
            cell.featuredButton.loadImage(urlString: self.imageURLStrings[indexPath.row], placeholderImage: UIImage(named: "KiavashFaisali"), controlState: .normal, isBackgroundImage: false)
            
            return cell
        }
    }
}
