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
        Asynchronously downloads an image and loads it into the `MKAnnotationView` using a URL `String`.
        
        - parameter urlString: The image URL in the form of a `String`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final public func loadImage(urlString: String,
                         placeholderImage: UIImage? = nil,
                               completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
               completion?(false, nil)
            }
            
            return
        }
        
        loadImage(url: url, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `MKAnnotationView` using a `URL`.
        
        - parameter url: The image `URL`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final public func loadImage(url: URL,
                   placeholderImage: UIImage? = nil,
                         completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        let cacheManager = KFImageCacheManager.sharedInstance
        
        var request = URLRequest(url: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        loadImage(request: request, placeholderImage: placeholderImage, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `MKAnnotationView` using a `URLRequest`.
        
        - parameter request: The image URL in the form of a `URLRequest`.
        - parameter placeholderImage: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `NSError?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final public func loadImage(request: URLRequest,
                       placeholderImage: UIImage? = nil,
                             completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil)
    {
        self.completionHolder = CompletionHolder(completion: completion)
        
        guard let urlAbsoluteString = request.url?.absoluteString else {
            self.completionHolder.completion?(false, nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.sharedInstance
        let fadeAnimationDuration = cacheManager.fadeAnimationDuration
        let sharedURLCache = URLCache.shared
        
        func loadImage(_ image: UIImage) -> Void {
            UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                self.image = image
            })
            
            self.completionHolder.completion?(true, nil)
        }
        
        // If there's already a cached image, load it into the image view.
        if let image = cacheManager[urlAbsoluteString] {
            loadImage(image)
        }
        // If there's already a cached response, load the image data into the image view.
        else if let cachedResponse = sharedURLCache.cachedResponse(for: request), let image = UIImage(data: cachedResponse.data), let creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval, (Date.timeIntervalSinceReferenceDate - creationTimestamp) < Double(cacheManager.diskCacheMaxAge) {
            loadImage(image)
            
            cacheManager[urlAbsoluteString] = image
        }
        // Either begin downloading the image or become an observer for an existing request.
        else {
            // Remove the stale disk-cached response (if any).
            sharedURLCache.removeCachedResponse(for: request)
            
            // Set the placeholder image if it was provided.
            if let image = placeholderImage {
                self.image = image
            }
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, forURLString: urlAbsoluteString)
                
                let dataTask = cacheManager.session.dataTask(with: request) {
                    taskData, taskResponse, taskError in
                    
                    guard let data = taskData, let response = taskResponse, let image = UIImage(data: data), taskError == nil else {
                        DispatchQueue.main.async {
                            cacheManager.setIsDownloadingFromURL(false, forURLString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                            self.completionHolder.completion?(false, taskError as NSError?)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                            self.image = image
                        })
                        
                        cacheManager[urlAbsoluteString] = image
                        
                        let responseDataIsCacheable = cacheManager.diskCacheMaxAge > 0 &&
                            Double(data.count) <= 0.05 * Double(sharedURLCache.diskCapacity) &&
                            (cacheManager.session.configuration.requestCachePolicy == .returnCacheDataElseLoad ||
                                cacheManager.session.configuration.requestCachePolicy == .returnCacheDataDontLoad) &&
                            (request.cachePolicy == .returnCacheDataElseLoad ||
                                request.cachePolicy == .returnCacheDataDontLoad)
                        
                        if let httpResponse = response as? HTTPURLResponse, let url = httpResponse.url, responseDataIsCacheable {
                            if var allHeaderFields = httpResponse.allHeaderFields as? [String: String] {
                                allHeaderFields["Cache-Control"] = "max-age=\(cacheManager.diskCacheMaxAge)"
                                if let cacheControlResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: allHeaderFields) {
                                    let cachedResponse = CachedURLResponse(response: cacheControlResponse, data: data, userInfo: ["creationTimestamp": Date.timeIntervalSinceReferenceDate], storagePolicy: .allowed)
                                    sharedURLCache.storeCachedResponse(cachedResponse, for: request)
                                }
                            }
                        }
                        
                        self.completionHolder.completion?(true, nil)
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
