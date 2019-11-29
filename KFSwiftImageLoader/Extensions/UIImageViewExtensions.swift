//
//  Created by Kiavash Faisali on 2015-03-17.
//  Copyright (c) 2015 Kiavash Faisali. All rights reserved.
//

#if os(iOS)
import UIKit

// MARK: - UIImageView Associated Value Keys
fileprivate var indexPathIdentifierAssociationKey: UInt8 = 0
fileprivate var completionAssociationKey: UInt8 = 0

// MARK: - UIImageView Extensions
extension UIImageView: AssociatedValue {}

public extension UIImageView {
    // MARK: - Associated Values
    final internal var indexPathIdentifier: Int {
        get {
            return getAssociatedValue(key: &indexPathIdentifierAssociationKey, defaultValue: -1)
        }
        set {
            setAssociatedValue(key: &indexPathIdentifierAssociationKey, value: newValue)
        }
    }
    
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
        Asynchronously downloads an image and loads it into the `UIImageView` using a URL `String`.
        
        - parameter urlString: The image URL in the form of a `String`.
        - parameter placeholder: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
    */
    final func loadImage(urlString: String,
                              placeholder: UIImage? = nil,
                               completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion?(false, nil)
            }
            
            return
        }
        
        loadImage(url: url, placeholder: placeholder, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `UIImageView` using a `URL`.
     
        - parameter url: The image `URL`.
        - parameter placeholder: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
     */
    final func loadImage(url: URL,
                        placeholder: UIImage? = nil,
                         completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        let cacheManager = KFImageCacheManager.shared
        
        var request = URLRequest(url: url, cachePolicy: cacheManager.session.configuration.requestCachePolicy, timeoutInterval: cacheManager.session.configuration.timeoutIntervalForRequest)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        loadImage(request: request, placeholder: placeholder, completion: completion)
    }
    
    /**
        Asynchronously downloads an image and loads it into the `UIImageView` using a `URLRequest`.
     
        - parameter request: The image URL in the form of a `URLRequest`.
        - parameter placeholder: `UIImage?` representing a placeholder image that is loaded into the view while the asynchronous download takes place. The default value is `nil`.
        - parameter completion: An optional closure that is called to indicate completion of the intended purpose of this method. It returns two values: the first is a `Bool` indicating whether everything was successful, and the second is `Error?` which will be non-nil should an error occur. The default value is `nil`.
     */
    final func loadImage(request: URLRequest,
                            placeholder: UIImage? = nil,
                             completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
    {
        self.completion = completion
        self.indexPathIdentifier = -1
        
        guard let urlAbsoluteString = request.url?.absoluteString else {
            self.completion?(false, nil)
            return
        }
        
        let cacheManager = KFImageCacheManager.shared
        let fadeAnimationDuration = cacheManager.fadeAnimationDuration
        let sharedURLCache = URLCache.shared
        
        func loadImage(_ image: UIImage) -> Void {
            UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                self.image = image
            })
            
            self.completion?(true, nil)
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
            if let placeholder = placeholder {
                self.image = placeholder
            }
            
            var parentView = self.superview

            // Should the image be shown in a cell, walk the view hierarchy to retrieve the index path from the tableview or collectionview.
            while parentView != nil {
                switch parentView {
                case let tableViewCell as UITableViewCell:
                    // Every tableview cell must be directly embedded within a tableview.
                    if let tableView = tableViewCell.superview as? UITableView,
                        let indexPath = tableView.indexPathForRow(at: tableViewCell.center)
                    {
                        self.indexPathIdentifier = indexPath.hashValue
                    }
                case let collectionViewCell as UICollectionViewCell:
                    // Every collectionview cell must be directly embedded within a collectionview.
                    if let collectionView = collectionViewCell.superview as? UICollectionView,
                        let indexPath = collectionView.indexPathForItem(at: collectionViewCell.center)
                    {
                        self.indexPathIdentifier = indexPath.hashValue
                    }
                default:
                    break
                }
                
                parentView = parentView?.superview
            }
            
            let initialIndexIdentifier = self.indexPathIdentifier
            
            // If the image isn't already being downloaded, begin downloading the image.
            if cacheManager.isDownloadingFromURL(urlAbsoluteString) == false {
                cacheManager.setIsDownloadingFromURL(true, urlString: urlAbsoluteString)
                
                let dataTask = cacheManager.session.dataTask(with: request) {
                    taskData, taskResponse, taskError in
                    
                    guard let data = taskData, let response = taskResponse, let image = UIImage(data: data), taskError == nil else {
                        DispatchQueue.main.async {
                            cacheManager.setIsDownloadingFromURL(false, urlString: urlAbsoluteString)
                            cacheManager.removeImageCacheObserversForKey(urlAbsoluteString)
                            self.completion?(false, taskError)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if initialIndexIdentifier == self.indexPathIdentifier {
                            UIView.transition(with: self, duration: fadeAnimationDuration, options: .transitionCrossDissolve, animations: {
                                self.image = image
                            })
                        }
                        
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
            // Since the image is already being downloaded and hasn't been cached, register the image view as a cache observer.
            else {
                weak var weakSelf = self
                cacheManager.addImageCacheObserver(weakSelf!, initialIndexIdentifier: initialIndexIdentifier, key: urlAbsoluteString)
            }
        }
    }
}
#endif
