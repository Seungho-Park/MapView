//
//  CacheWrapper.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

import Foundation

final class CacheWrapper<T>: NSObject, NSDiscardableContent {
    var value: T
    
    init(value: T) {
        self.value = value
    }
    
    func beginContentAccess() -> Bool {
        return true
    }
    
    func endContentAccess() {
        
    }
    
    func discardContentIfPossible() {
        
    }
    
    func isContentDiscarded() -> Bool {
        return false
    }
}
