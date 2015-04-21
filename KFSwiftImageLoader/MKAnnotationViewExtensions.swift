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
            objc_setAssociatedObject(self, &completionHolderAssociationKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
        }
    }
    
    // MARK: - Image Loading Methods
    /**
    Asynchronously downloads an image and loads it into the view using a URL string.
    
    :param: string The image URL in the form of a String.
    :param: placeholderImage An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
    :param: completion An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURLString(string: String, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil) {
        if let url = NSURL(string: string) {
            loadImageFromURL(url, placeholderImage: placeholderImage, completion: completion)
        }
    }
    
    /**
    Asynchronously downloads an image and loads it into the view using an NSURL object.
    
    :param: url The image URL in the form of an NSURL object.
    :param: placeholderImage An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
    :param: completion An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURL(url: NSURL, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil) {
        let cacheManager = KFImageCacheManager.sharedInstance
        let request = NSMutableURLRequest(URL: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        loadImageFromRequest(request, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
    Asynchronously downloads an image and loads it into the view using an NSURLRequest object.
    
    :param: request The image URL in the form of an NSURLRequest object.
    :param: placeholderImage An optional UIImage representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is nil.
    :param: completion An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromRequest(request: NSURLRequest, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil) {
        self.completionHolder = CompletionHolder(completion: completion)
        
        if request.URL?.absoluteString == nil {
            self.completionHolder.completion?(finished: false, error: nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.sharedInstance
        let fadeAnimationDuration = cacheManager.fadeAnimationDuration
        let urlAbsoluteString = request.URL!.absoluteString!
        
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
        else if let cachedResponse = NSURLCache.sharedURLCache().cachedResponseForRequest(request), image = UIImage(data: cachedResponse.data), creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval where (CACurrentMediaTime() - creationTimestamp) < Double(cacheManager.diskCacheMaxAge) {
            loadImage(image)
            
            cacheManager[urlAbsoluteString] = image
        }
        // Either begin downloading the image or become an observer for an existing request.
        else {
            // Remove the stale disk-cached response (if any).
            NSURLCache.sharedURLCache().removeCachedResponseForRequest(request)
            
            // Set the placeholder image if it was provided.
            if let image = placeholderImage {
                self.image = image
            }
            
            let initialIndexIdentifier = -1
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, forURLString: urlAbsoluteString)
                
                let dataTask = cacheManager.session.dataTaskWithRequest(request) {
                    (data: NSData!, response: NSURLResponse!, error: NSError!) in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        var finished = false
                        
                        // If there is no error, load the image into the image view and cache it.
                        if error == nil {
                            if let image = UIImage(data: data) {
                                UIView.transitionWithView(self, duration: fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                                    self.image = image
                                }, completion: nil)
                                
                                cacheManager[urlAbsoluteString] = image
                                
                                let responseDataIsCacheable = cacheManager.diskCacheMaxAge > 0 &&
                                    Double(data.length) <= 0.05 * Double(NSURLCache.sharedURLCache().diskCapacity) &&
                                    (cacheManager.session.configuration.requestCachePolicy == .ReturnCacheDataElseLoad ||
                                        cacheManager.session.configuration.requestCachePolicy == .ReturnCacheDataDontLoad) &&
                                    (request.cachePolicy == .ReturnCacheDataElseLoad ||
                                        request.cachePolicy == .ReturnCacheDataDontLoad)
                                
                                if let httpResponse = response as? NSHTTPURLResponse, url = httpResponse.URL where responseDataIsCacheable {
                                    var allHeaderFields = httpResponse.allHeaderFields
                                    allHeaderFields["Cache-Control"] = "max-age=\(cacheManager.diskCacheMaxAge)"
                                    if let cacheControlResponse = NSHTTPURLResponse(URL: url, statusCode: httpResponse.statusCode, HTTPVersion: "HTTP/1.1", headerFields: allHeaderFields) {
                                        let cachedResponse = NSCachedURLResponse(response: cacheControlResponse, data: data, userInfo: ["creationTimestamp": CACurrentMediaTime()], storagePolicy: .Allowed)
                                        NSURLCache.sharedURLCache().storeCachedResponse(cachedResponse, forRequest: request)
                                    }
                                }
                                
                                finished = true
                            }
                        }
                        
                        // If there was an error or image data wasn't returned, remove the observers and set isDownloading to false.
                        if finished == false {
                            cacheManager.setIsDownloadingFromURL(false, forURLString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                        }
                        
                        self.completionHolder.completion?(finished: finished, error: error)
                    }
                }
                
                dataTask.resume()
            }
            // Since the image is already being downloaded and hasn't been cached, register the image view as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, withInitialIndexIdentifier: initialIndexIdentifier, forKey: urlAbsoluteString)
            }
        }
    }
}
