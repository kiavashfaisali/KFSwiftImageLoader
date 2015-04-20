//
//  Created by Kiavash Faisali on 2015-04-16.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import WatchKit
import KFSwiftImageLoader

final class HomeInterfaceController: WKInterfaceController {
    // MARK: - Properties
    @IBOutlet weak var animationImage: WKInterfaceImage!
    
    var imageURLStringsArray = [String]()
    
    // MARK: - Setup and Teardown
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Animations created using KFWatchKitAnimations.
        // https://github.com/kiavashfaisali/KFWatchKitAnimations
        let drawCircleDuration = 2.0
        self.animationImage.setImageNamed("drawGreenCircle-")
        self.animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, 118), duration: drawCircleDuration, repeatCount: 1)
        
        self.dispatchAnimationsAfterSeconds(drawCircleDuration) {
            let countdownDuration = 0.7
            self.animationImage.setImageNamed("removeBlur-")
            self.animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, 41), duration: countdownDuration, repeatCount: 1)
            
            self.dispatchAnimationsAfterSeconds(countdownDuration) {
                let verticalShiftDuration = 1.0
                self.animationImage.setImageNamed("verticalShiftAndFadeIn-")
                self.animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, 59), duration: verticalShiftDuration, repeatCount: 1)
                
                self.dispatchAnimationsAfterSeconds(verticalShiftDuration) {
                    let yellowCharacterDuration = 2.0
                    self.animationImage.setImageNamed("yellowCharacterJump-")
                    self.animationImage.startAnimatingWithImagesInRange(NSMakeRange(0, 110), duration: yellowCharacterDuration, repeatCount: 0)
                    self.loadDuckDuckGoResults()
                }
            }
        }
    }

    // MARK: - View Lifecycle
    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
    
    // MARK: - Miscellaneous Methods
    func loadDuckDuckGoResults() {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: "http://api.duckduckgo.com/?q=simpsons+characters&format=json")!
        let request = NSURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60.0)
        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            
            dispatch_async(dispatch_get_main_queue()) {
                if error == nil {
                    var jsonError: NSError?
                    if let jsonDict = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as? [String: AnyObject] where jsonError == nil {
                        if let relatedTopics = jsonDict["RelatedTopics"] as? [[String: AnyObject]] {
                            for relatedTopic in relatedTopics {
                                if let imageURLString = relatedTopic["Icon"]?["URL"] as? String {
                                    if imageURLString != "" {
                                        for i in 1...2 {
                                            self.imageURLStringsArray.append(imageURLString)
                                        }
                                    }
                                }
                            }
                            
                            if self.imageURLStringsArray.count > 0 {
                                // Uncomment to randomize the image ordering.
                                self.randomizeImages()
                                
                                WKInterfaceController.reloadRootControllersWithNames(["TableImageInterfaceController"], contexts: [self.imageURLStringsArray])
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
    
    func dispatchAnimationsAfterSeconds(seconds: Double, animations: () -> Void) {
        if seconds <= 0.0 {
            return
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.animationImage.stopAnimating()
            animations()
        }
    }
}
