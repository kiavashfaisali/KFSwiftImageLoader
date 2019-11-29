//
//  Created by Kiavash Faisali on 5/13/18.
//

import Foundation

// MARK: - AssociatedValue Protocol
internal protocol AssociatedValue {
    func getAssociatedValue<T>(key: UnsafeRawPointer, defaultValue: T?) -> T?
    func getAssociatedValue<T>(key: UnsafeRawPointer, defaultValue: T) -> T
    func setAssociatedValue<T>(key: UnsafeRawPointer, value: T?, policy: objc_AssociationPolicy)
}

// MARK: - AssociatedValue Protocol Default Implementation
internal extension AssociatedValue {
    func getAssociatedValue<T>(key: UnsafeRawPointer, defaultValue: T?) -> T? {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        
        return value
    }
    
    func getAssociatedValue<T>(key: UnsafeRawPointer, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        
        return value
    }
    
    func setAssociatedValue<T>(key: UnsafeRawPointer, value: T?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(self, key, value, policy)
    }
}
