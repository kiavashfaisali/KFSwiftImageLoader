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
                os_log("Error retrieving a response from the DuckDuckGo API: %{public}@", type: .error, error!.localizedDescription)
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
            let identifier = String(describing: ImageTableViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ImageTableViewCell
            
            cell.featuredImageView.loadImage(urlString: self.imageURLStrings[indexPath.row], placeholder: UIImage(named: "KiavashFaisali")) {
                (success, error) in
                
                guard error == nil else {
                    os_log("Error occurred when loading the image: %{public}@", type: .error, error!.localizedDescription)
                    return
                }
                
                if !success {
                    os_log("Image could not be loaded from the provided URL, or the index paths didn't match due to fast scrolling, which would've placed the image in an incorrect cell.", type: .info)
                }
            }
            
            return cell
        }
        // Odd indices should contain button cells.
        else {
            let identifier = String(describing: ButtonImageTableViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ButtonImageTableViewCell
            
            // Notice that the completion closure can be ommitted, since it defaults to nil. The `controlState` and `isBackground` parameters can also be ommitted, as they default to `.normal` and `false`, respectively.
            // Please read the documentation for more information.
            cell.featuredButton.loadImage(urlString: self.imageURLStrings[indexPath.row], placeholder: UIImage(named: "KiavashFaisali"), controlState: .normal, isBackground: false)
            
            return cell
        }
    }
}
