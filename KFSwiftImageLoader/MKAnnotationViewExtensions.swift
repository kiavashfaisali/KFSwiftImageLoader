/*
    KFSwiftImageLoader is available under the MIT license.

    Copyright (c) 2015 Kiavash Faisali
    https://github.com/kiavashfaisali

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//
//  Created by Kiavash Faisali on 2015-04-18.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit
import MapKit

// MARK: - MKAnnotationView Associated Object Keys
private var completionHolderAssociationKey: UInt8 = 0

// MARK: - MKAnnotationView Extension
public extension MKAnnotationView {
    // MARK: - Associated Objects
    final internal var completionHolder: CompletionHolder! {
        get {
            return objc_getAssociatedObject(self, &completionHolderAssociationKey) as? CompletionHolder
        }
        set {
            objc_setAssociatedObject(self, &completionHolderAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Image Loading Methods
    /**
        Asynchronously downloads an image and loads it into the view using a URL string.
        
        - parameter string: The image URL in the form of a String.
        - parameter placeholderImage: An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURLString(string: String, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        if let url = NSURL(string: string) {
            loadImageFromURL(url, placeholderImage: placeholderImage, completion: completion)
        }
    }
    
    /**
        Asynchronously downloads an image and loads it into the view using an NSURL object.
        
        - parameter url: The image URL in the form of an NSURL object.
        - parameter placeholderImage: An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURL(url: NSURL, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        let cacheManager = KFImageCacheManager.sharedInstance
        let request = NSMutableURLRequest(URL: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        loadImageFromRequest(request, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the view using an NSURLRequest object.
        
        - parameter request: The image URL in the form of an NSURLRequest object.
        - parameter placeholderImage: An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromRequest(request: NSURLRequest, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        self.completionHolder = CompletionHolder(completion: completion)
        
        guard let urlAbsoluteString = request.URL?.absoluteString else {
            self.completionHolder.completion?(finished: false, error: nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.sharedInstance
        let fadeAnimationDuration = cacheManager.fadeAnimationDuration
        let sharedURLCache = NSURLCache.sharedURLCache()
        
        func loadImage(image: UIImage) -> Void {
            UIView.transitionWithView(self, duration: fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
            
            self.completionHolder.completion?(finished: true, error: nil)
        }
        
        // If there's already a cached image, load it into the image view.
        if let image = cacheManager[urlAbsoluteString] {
            loadImage(image)
        }
        // If there's already a cached response, load the image data into the image view.
        else if let cachedResponse = sharedURLCache.cachedResponseForRequest(request), image = UIImage(data: cachedResponse.data), creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval where (NSDate.timeIntervalSinceReferenceDate() - creationTimestamp) < Double(cacheManager.diskCacheMaxAge) {
            loadImage(image)
            
            cacheManager[urlAbsoluteString] = image
        }
        // Either begin downloading the image or become an observer for an existing request.
        else {
            // Remove the stale disk-cached response (if any).
            sharedURLCache.removeCachedResponseForRequest(request)
            
            // Set the placeholder image if it was provided.
            if let image = placeholderImage {
                self.image = image
            }
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, forURLString: urlAbsoluteString)
                
                let dataTask = cacheManager.session.dataTaskWithRequest(request) {
                    (taskData: NSData?, taskResponse: NSURLResponse?, taskError: NSError?) in
                    
                    guard let data = taskData, response = taskResponse, image = UIImage(data: data) where taskError == nil else {
                        dispatch_async(dispatch_get_main_queue()) {
                            cacheManager.setIsDownloadingFromURL(false, forURLString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                            self.completionHolder.completion?(finished: false, error: taskError)
                        }
                        
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        UIView.transitionWithView(self, duration: fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                            self.image = image
                        }, completion: nil)
                        
                        cacheManager[urlAbsoluteString] = image
                        
                        let responseDataIsCacheable = cacheManager.diskCacheMaxAge > 0 &&
                            Double(data.length) <= 0.05 * Double(sharedURLCache.diskCapacity) &&
                            (cacheManager.session.configuration.requestCachePolicy == .ReturnCacheDataElseLoad ||
                                cacheManager.session.configuration.requestCachePolicy == .ReturnCacheDataDontLoad) &&
                            (request.cachePolicy == .ReturnCacheDataElseLoad ||
                                request.cachePolicy == .ReturnCacheDataDontLoad)
                        
                        if let httpResponse = response as? NSHTTPURLResponse, url = httpResponse.URL where responseDataIsCacheable {
                            if var allHeaderFields = httpResponse.allHeaderFields as? [String: String] {
                                allHeaderFields["Cache-Control"] = "max-age=\(cacheManager.diskCacheMaxAge)"
                                NSDate.timeIntervalSinceReferenceDate()
                                if let cacheControlResponse = NSHTTPURLResponse(URL: url, statusCode: httpResponse.statusCode, HTTPVersion: "HTTP/1.1", headerFields: allHeaderFields) {
                                    let cachedResponse = NSCachedURLResponse(response: cacheControlResponse, data: data, userInfo: ["creationTimestamp": NSDate.timeIntervalSinceReferenceDate()], storagePolicy: .Allowed)
                                    sharedURLCache.storeCachedResponse(cachedResponse, forRequest: request)
                                }
                            }
                        }
                        
                        self.completionHolder.completion?(finished: true, error: nil)
                    }
                }
                
                dataTask.resume()
            }
            // Since the image is already being downloaded and hasn't been cached, register the image view as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, withInitialIndexIdentifier: -1, forKey: urlAbsoluteString)
            }
        }
    }
}
