/*
    KFSwiftImageLoader is available under the MIT license.

    Copyright (c) 2015 Kiavash Faisali
    https://github.com/kiavashfaisali

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

import UIKit
import MapKit
import WatchKit

// MARK: - CompletionHolder Class
final internal class CompletionHolder {
    var completion: ((finished: Bool, error: NSError?) -> Void)?
    
    init(completion: ((finished: Bool, error: NSError?) -> Void)?) {
        self.completion = completion
    }
}

// MARK: - KFImageCacheManager Class
final public class KFImageCacheManager {
    // MARK: - Properties
    private struct ImageCacheKeys {
        static let img = "img"
        static let isDownloading = "isDownloading"
        static let observerMapping = "observerMapping"
    }
    
    public static let sharedInstance = KFImageCacheManager()
    
    // {"url": {"img": UIImage, "isDownloading": Bool, "observerMapping": {Observer: Int}}}
    private var imageCache = [String: [String: AnyObject]]()
    
    internal lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = .ReturnCacheDataElseLoad
        configuration.URLCache = .sharedURLCache()
        return NSURLSession(configuration: configuration)
    }()
    
    /**
        Sets the fade duration time (in seconds) for images when they are being loaded into their views.
        A value of 0 implies no fade animation.
        The default value is 0.1 seconds.
        
        - returns: An NSTimeInterval value representing time in seconds.
    */
    public var fadeAnimationDuration: NSTimeInterval = 0.1
    
    /**
        Sets the maximum time (in seconds) that the disk cache will use to maintain a cached response.
        The default value is 604800 seconds (1 week).
        
        - returns: An unsigned integer value representing time in seconds.
    */
    public var diskCacheMaxAge: UInt = 60 * 60 * 24 * 7 {
        willSet {
            if newValue == 0 {
                NSURLCache.sharedURLCache().removeAllCachedResponses()
            }
        }
    }
    
    /**
        Sets the maximum time (in seconds) that the request should take before timing out.
        The default value is 60 seconds.
        
        - returns: An NSTimeInterval value representing time in seconds.
    */
    public var timeoutIntervalForRequest: NSTimeInterval = 60.0 {
        willSet {
            let configuration = self.session.configuration
            configuration.timeoutIntervalForRequest = newValue
            self.session = NSURLSession(configuration: configuration)
        }
    }
    
    /**
        Sets the cache policy which the default requests and underlying session configuration use to determine caching behaviour.
        The default value is ReturnCacheDataElseLoad.
        
        - returns: An NSURLRequestCachePolicy value representing the cache policy.
    */
    public var requestCachePolicy: NSURLRequestCachePolicy = .ReturnCacheDataElseLoad {
        willSet {
            let configuration = self.session.configuration
            configuration.requestCachePolicy = newValue
            self.session = NSURLSession(configuration: configuration)
        }
    }
    
    private init() {
        // Initialize the disk cache capacity to 50 MB.
        let diskURLCache = NSURLCache(memoryCapacity: 0, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(diskURLCache)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: NSOperationQueue.mainQueue()) {
            _ in
            
            self.imageCache.removeAll(keepCapacity: false)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Image Cache Subscripting
    internal subscript (key: String) -> UIImage? {
        get {
            return imageCacheEntryForKey(key)[ImageCacheKeys.img] as? UIImage
        }
        set {
            if let image = newValue {
                var imageCacheEntry = imageCacheEntryForKey(key)
                imageCacheEntry[ImageCacheKeys.img] = image
                setImageCacheEntry(imageCacheEntry, forKey: key)
                
                if let observerMapping = imageCacheEntry[ImageCacheKeys.observerMapping] as? [NSObject: Int] {
                    for (observer, initialIndexIdentifier) in observerMapping {
                        switch observer {
                        case let imageView as UIImageView:
                            loadObserverAsImageView(imageView, forImage: image, withInitialIndexIdentifier: initialIndexIdentifier)
                        case let button as UIButton:
                            loadObserverAsButton(button, forImage: image, withInitialIndexIdentifier: initialIndexIdentifier)
                        case let annotationView as MKAnnotationView:
                            loadObserverAsAnnotationView(annotationView, forImage: image)
                        case let interfaceImage as WKInterfaceImage:
                            loadObserverAsInterfaceImage(interfaceImage, forImage: image, withKey: key)
                        default:
                            break
                        }
                    }

                    removeImageCacheObserversForKey(key)
                }
            }
        }
    }
    
    // MARK: - Image Cache Methods
    internal func imageCacheEntryForKey(key: String) -> [String: AnyObject] {
        if let imageCacheEntry = self.imageCache[key] {
            return imageCacheEntry
        }
        else {
            let imageCacheEntry: [String: AnyObject] = [ImageCacheKeys.isDownloading: false, ImageCacheKeys.observerMapping: [NSObject: Int]()]
            self.imageCache[key] = imageCacheEntry
            return imageCacheEntry
        }
    }
    
    internal func setImageCacheEntry(imageCacheEntry: [String: AnyObject], forKey key: String) {
        self.imageCache[key] = imageCacheEntry
    }
    
    internal func isDownloadingFromURL(urlString: String) -> Bool {
        let isDownloading = imageCacheEntryForKey(urlString)[ImageCacheKeys.isDownloading] as? Bool
        
        return isDownloading ?? false
    }
    
    internal func setIsDownloadingFromURL(isDownloading: Bool, forURLString urlString: String) {
        var imageCacheEntry = imageCacheEntryForKey(urlString)
        imageCacheEntry[ImageCacheKeys.isDownloading] = isDownloading
        setImageCacheEntry(imageCacheEntry, forKey: urlString)
    }
    
    internal func addImageCacheObserver(observer: NSObject, withInitialIndexIdentifier initialIndexIdentifier: Int, forKey key: String) {
        var imageCacheEntry = imageCacheEntryForKey(key)
        if var observerMapping = imageCacheEntry[ImageCacheKeys.observerMapping] as? [NSObject: Int] {
            observerMapping[observer] = initialIndexIdentifier
            imageCacheEntry[ImageCacheKeys.observerMapping] = observerMapping
            setImageCacheEntry(imageCacheEntry, forKey: key)
        }
    }
    
    internal func removeImageCacheObserversForKey(key: String) {
        var imageCacheEntry = imageCacheEntryForKey(key)
        if var observerMapping = imageCacheEntry[ImageCacheKeys.observerMapping] as? [NSObject: Int] {
            observerMapping.removeAll(keepCapacity: false)
            imageCacheEntry[ImageCacheKeys.observerMapping] = observerMapping
            setImageCacheEntry(imageCacheEntry, forKey: key)
        }
    }
    
    // MARK: - Observer Methods
    internal func loadObserverAsImageView(observer: UIImageView, forImage image: UIImage, withInitialIndexIdentifier initialIndexIdentifier: Int) {
        if initialIndexIdentifier == observer.indexPathIdentifier {
            dispatch_async(dispatch_get_main_queue()) {
                UIView.transitionWithView(observer, duration: self.fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                    observer.image = image
                }, completion: nil)
                
                observer.completionHolder.completion?(finished: true, error: nil)
            }
        }
        else {
            observer.completionHolder.completion?(finished: false, error: nil)
        }
    }
    
    internal func loadObserverAsButton(observer: UIButton, forImage image: UIImage, withInitialIndexIdentifier initialIndexIdentifier: Int) {
        if initialIndexIdentifier == observer.indexPathIdentifier {
            dispatch_async(dispatch_get_main_queue()) {
                UIView.transitionWithView(observer, duration: self.fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                    if observer.isBackgroundImage == true {
                        observer.setBackgroundImage(image, forState: observer.controlStateHolder.controlState)
                    }
                    else {
                        observer.setImage(image, forState: observer.controlStateHolder.controlState)
                    }
                }, completion: nil)
                
                observer.completionHolder.completion?(finished: true, error: nil)
            }
        }
        else {
            observer.completionHolder.completion?(finished: false, error: nil)
        }
    }
    
    internal func loadObserverAsAnnotationView(observer: MKAnnotationView, forImage image: UIImage) {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.transitionWithView(observer, duration: self.fadeAnimationDuration, options: .TransitionCrossDissolve, animations: {
                observer.image = image
            }, completion: nil)
            
            observer.completionHolder.completion?(finished: true, error: nil)
        }
    }
    
    internal func loadObserverAsInterfaceImage(observer: WKInterfaceImage, forImage image: UIImage, withKey key: String) {
        dispatch_async(dispatch_get_main_queue()) {
            // If there's already a cached image on the Apple Watch, simply set the image directly.
            if WKInterfaceDevice.currentDevice().cachedImages[key] != nil {
                observer.setImageNamed(key)
            }
            else {
                observer.setImageData(UIImagePNGRepresentation(image))
            }
            
            observer.completionHolder.completion?(finished: true, error: nil)
        }
    }
}
