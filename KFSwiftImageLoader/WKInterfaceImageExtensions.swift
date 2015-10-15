/*
    KFSwiftImageLoader is available under the MIT license.

    Copyright (c) 2015 Kiavash Faisali
    https://github.com/kiavashfaisali

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//
//  Created by Kiavash Faisali on 2015-04-16.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import WatchKit

// MARK: - WKInterfaceImage Associated Object Keys
private var completionHolderAssociationKey: UInt8 = 0

// MARK: - WKInterfaceImage Extension
public extension WKInterfaceImage {
    // MARK: - Associated Objects
    final internal var completionHolder: CompletionHolder! {
        get {
            return objc_getAssociatedObject(self, &completionHolderAssociationKey) as? CompletionHolder
        }
        set {
            objc_setAssociatedObject(self, &completionHolderAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Helper Methods
    final private func storeImageDataInDeviceCache(imageData: NSData, forURLAbsoluteString urlAbsoluteString: String) {
        // Max cache size is 5 MB.
        let maxCacheSize = 5 * 1024 * 1024
        var cacheTotalCost = imageData.length
        let currentDevice = WKInterfaceDevice.currentDevice()
        
        // If the image data is too big to be stored into the device's cache, then fallback to the Bluetooth transfer method.
        if cacheTotalCost > maxCacheSize {
            self.setImageData(imageData)
        }
        else {
            for (urlString, cacheCostNumber) in currentDevice.cachedImages {
                cacheTotalCost += cacheCostNumber.integerValue
                
                // Check if the total cost would exceed the max cache size of 5 MB.
                if cacheTotalCost > maxCacheSize {
                    // Evict the current loop item from the cache to make space.
                    currentDevice.removeCachedImageWithName(urlString)
                }
            }
            
            if currentDevice.addCachedImageWithData(imageData, name: urlAbsoluteString) {
                self.setImageNamed(urlAbsoluteString)
            }
            else {
                self.setImageData(imageData)
            }
        }
    }
    
    // MARK: - Image Loading Methods
    /**
        Asynchronously downloads an image and loads it into the interface using a URL string.
        
        - parameter string: The image URL in the form of a String.
        - parameter placeholderImageName: An optional String representing the name of a placeholder image that is loaded into the interface while the asynchronous download takes place. The default value is nil.
        - parameter shouldUseDeviceCache: A boolean indicating whether or not to use the  Watch's device cache for dramatically improved performance. This should only be considered for images that are likely to be loaded more than once throughout the lifetime of the app.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURLString(string: String, placeholderImageName: String? = nil, shouldUseDeviceCache: Bool = false, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        if let url = NSURL(string: string) {
            loadImageFromURL(url, placeholderImageName: placeholderImageName, shouldUseDeviceCache: shouldUseDeviceCache, completion: completion)
        }
    }
    
    /**
        Asynchronously downloads an image and loads it into the interface using an NSURL object.
        
        - parameter url: The image URL in the form of an NSURL object.
        - parameter placeholderImageName: An optional String representing the name of a placeholder image that is loaded into the interface while the asynchronous download takes place. The default value is nil.
        - parameter shouldUseDeviceCache: A boolean indicating whether or not to use the  Watch's device cache for dramatically improved performance. This should only be considered for images that are likely to be loaded more than once throughout the lifetime of the app.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromURL(url: NSURL, placeholderImageName: String? = nil, shouldUseDeviceCache: Bool = false, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        let cacheManager = KFImageCacheManager.sharedInstance
        let request = NSMutableURLRequest(URL: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        loadImageFromRequest(request, placeholderImageName: placeholderImageName, shouldUseDeviceCache: shouldUseDeviceCache, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the interface using an NSURLRequest object.
        
        - parameter request: The image URL in the form of an NSURLRequest object.
        - parameter placeholderImageName: An optional String representing the name of a placeholder image that is loaded into the interface while the asynchronous download takes place. The default value is nil.
        - parameter shouldUseDeviceCache: A boolean indicating whether or not to use the  Watch's device cache for dramatically improved performance. This should only be considered for images that are likely to be loaded more than once throughout the lifetime of the app.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a Bool indicating whether everything was successful, and the second is an optional NSError which will be non-nil should an error occur. The default value is nil.
    */
    final public func loadImageFromRequest(request: NSURLRequest, placeholderImageName: String? = nil, shouldUseDeviceCache: Bool = false, completion: ((finished: Bool, error: NSError?) -> Void)? = nil) {
        self.completionHolder = CompletionHolder(completion: completion)
        
        guard let urlAbsoluteString = request.URL?.absoluteString else {
            self.completionHolder.completion?(finished: false, error: nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.sharedInstance
        let initialIndexIdentifier = -1
        let currentDevice = WKInterfaceDevice.currentDevice()
        let sharedURLCache = NSURLCache.sharedURLCache()
        
        if shouldUseDeviceCache {
            // If there's already a cached image on the Apple Watch, simply set the image directly.
            if currentDevice.cachedImages[urlAbsoluteString] != nil {
                self.setImageNamed(urlAbsoluteString)
                self.completionHolder.completion?(finished: true, error: nil)
                return
            }
        }
        else {
            // Since the decision was made to not use the Apple Watch's device cache, remove the stale image currently stored (if any).
            currentDevice.removeCachedImageWithName(urlAbsoluteString)
        }
        
        // If there's already a cached image, load it into the interface.
        if let image = cacheManager[urlAbsoluteString], imageData = UIImagePNGRepresentation(image) {
            if shouldUseDeviceCache {
                storeImageDataInDeviceCache(imageData, forURLAbsoluteString: urlAbsoluteString)
            }
            else {
                self.setImageData(imageData)
            }
            
            self.completionHolder.completion?(finished: true, error: nil)
        }
        // If there's already a cached response, load the image data into the interface.
        else if let cachedResponse = sharedURLCache.cachedResponseForRequest(request), image = UIImage(data: cachedResponse.data), creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval where (NSDate.timeIntervalSinceReferenceDate() - creationTimestamp) < Double(cacheManager.diskCacheMaxAge) {
            if shouldUseDeviceCache {
                storeImageDataInDeviceCache(cachedResponse.data, forURLAbsoluteString: urlAbsoluteString)
            }
            else {
                self.setImageData(cachedResponse.data)
            }
            
            cacheManager[urlAbsoluteString] = image
            self.completionHolder.completion?(finished: true, error: nil)
        }
        // Either begin downloading the image or become an observer for an existing request.
        else {
            // Remove the stale disk-cached response (if any).
            sharedURLCache.removeCachedResponseForRequest(request)
            
            // Set the placeholder image if it was provided.
            if let imageName = placeholderImageName {
                self.setImageNamed(imageName)
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
                        if shouldUseDeviceCache {
                            self.storeImageDataInDeviceCache(data, forURLAbsoluteString: urlAbsoluteString)
                        }
                        else {
                            self.setImage(image)
                        }
                        
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
            // Since the image is already being downloaded and hasn't been cached, register the interface as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, withInitialIndexIdentifier: initialIndexIdentifier, forKey: urlAbsoluteString)
            }
        }
    }
}
