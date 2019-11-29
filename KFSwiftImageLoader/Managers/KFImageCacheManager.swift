//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

#if os(iOS)
import UIKit
import MapKit
#endif

#if os(watchOS)
import WatchKit
#endif

// MARK: - ImageCacheKeys Struct
fileprivate enum ImageCacheKey {
    case image, isDownloading, observerMapping
}

// MARK: - KFImageCacheManager Class
final public class KFImageCacheManager {
    // MARK: - Properties
    public static let shared = KFImageCacheManager()
    
    // {"url": {.image: UIImage, .isDownloading: Bool, .observerMapping: {Observer: Int}}}
    fileprivate var imageCache = [String: [ImageCacheKey: Any]]()
    
    internal lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = .shared
        
        return URLSession(configuration: configuration)
    }()
    
    /**
        Sets the fade duration time (in seconds) for images when they are being loaded into their views.
        A value of 0 implies no fade animation.
        The default value is 0.1 seconds.
        
        - returns: TimeInterval value representing time in seconds.
    */
    public var fadeAnimationDuration = 0.1 as TimeInterval
    
    /**
        Sets the maximum time (in seconds) that the disk cache will use to maintain a cached response.
        The default value is 604800 seconds (1 week).
        
        - returns: UInt value representing time in seconds.
    */
    public var diskCacheMaxAge = 60 * 60 * 24 * 7 as UInt {
        willSet {
            if newValue == 0 {
                URLCache.shared.removeAllCachedResponses()
            }
        }
    }
    
    /**
        Sets the maximum time (in seconds) that the request should take before timing out.
        The default value is 60 seconds.
        
        - returns: TimeInterval value representing time in seconds.
    */
    public var timeoutIntervalForRequest = 60.0 as TimeInterval {
        willSet {
            let configuration = self.session.configuration
            configuration.timeoutIntervalForRequest = newValue
            self.session = URLSession(configuration: configuration)
        }
    }
    
    /**
        Sets the cache policy which the default requests and underlying session configuration use to determine caching behaviour.
        The default value is `returnCacheDataElseLoad`.
        
        - returns: URLRequest.CachePolicy value representing the cache policy.
    */
    public var requestCachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad {
        willSet {
            let configuration = self.session.configuration
            configuration.requestCachePolicy = newValue
            self.session = URLSession(configuration: configuration)
        }
    }
    
    fileprivate init() {
        // Initialize the disk cache capacity to 50 MB.
        let diskURLCache = URLCache(memoryCapacity: 0, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        URLCache.shared = diskURLCache

        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) {
            _ in
            
            self.imageCache.removeAll(keepingCapacity: false)
        }
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Image Cache Subscripting
    internal subscript (key: String) -> UIImage? {
        get {
            return imageCacheEntryForKey(key)[.image] as? UIImage
        }
        set {
            if let image = newValue {
                var imageCacheEntry = imageCacheEntryForKey(key)
                imageCacheEntry[.image] = image
                setImageCacheEntry(imageCacheEntry, key: key)
                
                if let observerMapping = imageCacheEntry[.observerMapping] as? [NSObject: Int] {
                    for (observer, initialIndexIdentifier) in observerMapping {
                        switch observer {
                        #if os(iOS)
                        case let imageView as UIImageView:
                            loadObserver(imageView, image: image, initialIndexIdentifier: initialIndexIdentifier)
                        case let button as UIButton:
                            loadObserver(button, image: image, initialIndexIdentifier: initialIndexIdentifier)
                        case let annotationView as MKAnnotationView:
                            loadObserver(annotationView, image: image)
                        #endif
                        #if os(watchOS)
                        case let interfaceImage as WKInterfaceImage:
                            loadObserver(interfaceImage, image: image)
                        #endif
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
    fileprivate func imageCacheEntryForKey(_ key: String) -> [ImageCacheKey: Any] {
        if let imageCacheEntry = self.imageCache[key] {
            return imageCacheEntry
        }
        else {
            let imageCacheEntry: [ImageCacheKey: Any] = [.isDownloading: false, .observerMapping: [NSObject: Int]()]
            self.imageCache[key] = imageCacheEntry
            
            return imageCacheEntry
        }
    }
    
    fileprivate func setImageCacheEntry(_ imageCacheEntry: [ImageCacheKey: Any], key: String) {
        self.imageCache[key] = imageCacheEntry
    }
    
    internal func isDownloadingFromURL(_ urlString: String) -> Bool {
        let isDownloading = imageCacheEntryForKey(urlString)[.isDownloading] as? Bool
        
        return isDownloading ?? false
    }
    
    internal func setIsDownloadingFromURL(_ isDownloading: Bool, urlString: String) {
        var imageCacheEntry = imageCacheEntryForKey(urlString)
        imageCacheEntry[.isDownloading] = isDownloading
        setImageCacheEntry(imageCacheEntry, key: urlString)
    }
    
    internal func addImageCacheObserver(_ observer: NSObject, initialIndexIdentifier: Int, key: String) {
        var imageCacheEntry = imageCacheEntryForKey(key)
        if var observerMapping = imageCacheEntry[.observerMapping] as? [NSObject: Int] {
            observerMapping[observer] = initialIndexIdentifier
            imageCacheEntry[.observerMapping] = observerMapping
            setImageCacheEntry(imageCacheEntry, key: key)
        }
    }
    
    internal func removeImageCacheObserversForKey(_ key: String) {
        var imageCacheEntry = imageCacheEntryForKey(key)
        if var observerMapping = imageCacheEntry[.observerMapping] as? [NSObject: Int] {
            observerMapping.removeAll(keepingCapacity: false)
            imageCacheEntry[.observerMapping] = observerMapping
            setImageCacheEntry(imageCacheEntry, key: key)
        }
    }
    
    // MARK: - Observer Methods
    #if os(iOS)
    internal func loadObserver(_ imageView: UIImageView, image: UIImage, initialIndexIdentifier: Int) {
        let success = initialIndexIdentifier == imageView.indexPathIdentifier
        
        if success {
            DispatchQueue.main.async {
                UIView.transition(with: imageView,
                              duration: self.fadeAnimationDuration,
                               options: .transitionCrossDissolve,
                            animations: {
                    imageView.image = image
                })
            }
        }
        
        imageView.completion?(success, nil)
    }
    
    internal func loadObserver(_ button: UIButton, image: UIImage, initialIndexIdentifier: Int) {
        let success = initialIndexIdentifier == button.indexPathIdentifier
        
        if success {
            DispatchQueue.main.async {
                UIView.transition(with: button,
                              duration: self.fadeAnimationDuration,
                               options: .transitionCrossDissolve,
                            animations: {
                    if button.isBackground {
                        button.setBackgroundImage(image, for: button.controlState)
                    }
                    else {
                        button.setImage(image, for: button.controlState)
                    }
                })
            }
        }
        
        button.completion?(success, nil)
    }
    
    internal func loadObserver(_ annotationView: MKAnnotationView, image: UIImage) {
        DispatchQueue.main.async {
            UIView.transition(with: annotationView,
                          duration: self.fadeAnimationDuration,
                           options: .transitionCrossDissolve,
                        animations: {
                annotationView.image = image
            })
            
            annotationView.completion?(true, nil)
        }
    }
    #endif

    #if os(watchOS)
    internal func loadObserver(_ interfaceImage: WKInterfaceImage, image: UIImage) {
        DispatchQueue.main.async {
            interfaceImage.setImage(image)
            interfaceImage.completion?(true, nil)
        }
    }
    #endif
}
