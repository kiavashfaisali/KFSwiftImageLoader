//
//  Created by Kiavash Faisali on 2015-04-16.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

#if os(watchOS)
import WatchKit

// MARK: - WKInterfaceImage Associated Value Keys
fileprivate var completionAssociationKey: UInt8 = 0

// MARK: - WKInterfaceImage Extensions
extension WKInterfaceImage: AssociatedValue {}

public extension WKInterfaceImage {
    // MARK: - Associated Values
    final internal var completion: ((_ finished: Bool, _ error: Error?) -> Void)? {
        get {
            return getAssociatedValue(key: &completionAssociationKey, defaultValue: nil)
        }
        set {
            setAssociatedValue(key: &completionAssociationKey, value: newValue)
        }
    }
    
    // MARK: - Image Loading Methods
    /**
        Asynchronously downloads an image and loads it into the `WKInterfaceImage` using a URL `String`.
        
        - parameter urlString: The image URL in the form of a `String`.
        - parameter placeholderName: `String?` representing the name of a placeholder image that is loaded into the `WKInterfaceImage` while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final func loadImage(urlString: String,
                          placeholderName: String? = nil,
                               completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion?(false, nil)
            }
            
            return
        }
        
        loadImage(url: url, placeholderName: placeholderName, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `WKInterfaceImage` using a `URL`.
        
        - parameter url: The image `URL`.
        - parameter placeholderName: `String?` representing the name of a placeholder image that is loaded into the `WKInterfaceImage` while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final func loadImage(url: URL,
                    placeholderName: String? = nil,
                         completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        let cacheManager = KFImageCacheManager.shared
        
        var request = URLRequest(url: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        loadImage(request: request, placeholderName: placeholderName, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `WKInterfaceImage` using a `URLRequest`.
        
        - parameter request: The image URL in the form of a `URLRequest`.
        - parameter placeholderName: `String?` representing the name of a placeholder image that is loaded into the `WKInterfaceImage` while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final func loadImage(request: URLRequest,
                        placeholderName: String? = nil,
                             completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        self.completion = completion
        
        guard let urlAbsoluteString = request.url?.absoluteString else {
            self.completion?(false, nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.shared
        let initialIndexIdentifier = -1
        let sharedURLCache = URLCache.shared
        
        // If there's already a cached image, load it into the interface.
        if let image = cacheManager[urlAbsoluteString], let imageData = image.pngData() {
            self.setImageData(imageData)
            
            self.completion?(true, nil)
        }
        // If there's already a cached response, load the image data into the interface.
        else if let cachedResponse = sharedURLCache.cachedResponse(for: request),
            let image = UIImage(data: cachedResponse.data),
            let creationTimestamp = cachedResponse.userInfo?["creationTimestamp"] as? CFTimeInterval,
            (Date.timeIntervalSinceReferenceDate - creationTimestamp) < Double(cacheManager.diskCacheMaxAge)
        {
            self.setImageData(cachedResponse.data)
            
            cacheManager[urlAbsoluteString] = image
            self.completion?(true, nil)
        }
        // Either begin downloading the image or become an observer for an existing request.
        else {
            // Remove the stale disk-cached response (if any).
            sharedURLCache.removeCachedResponse(for: request)
            
            // Set the placeholder image if it was provided.
            if let placeholderName = placeholderName {
                self.setImageNamed(placeholderName)
            }
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, urlString: urlAbsoluteString)
                
                let dataTask = cacheManager.session.dataTask(with: request) {
                    (data, response, error) in
                    
                    guard let data = data, let response = response, let image = UIImage(data: data), error == nil else {
                        DispatchQueue.main.async {
                            cacheManager.setIsDownloadingFromURL(false, urlString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                            self.completion?(false, error)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.setImage(image)
                        
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
                        
                        self.completion?(true, nil)
                    }
                }
                
                dataTask.resume()
            }
            // Since the image is already being downloaded and hasn't been cached, register the interface as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, initialIndexIdentifier: initialIndexIdentifier, key: urlAbsoluteString)
            }
        }
    }
}
#endif
