//
//  WMSCache.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

import Foundation

protocol MapCache {
    associatedtype CacheType
    
    var cache: NSCache<NSString, CacheWrapper<CacheType>> { get set }
    var capacity: Int { get }
    
    func clear()
    func update(_ value: CacheType, forKey key: String)
    func get(forKey key: String)-> CacheType?
    
    @discardableResult
    func removeValue(forKey key: String)-> CacheType?
    func contains(_ key: String)-> Bool
    
    var count: Int { get }
}

extension MapCache {
    func contains(_ key: String)-> Bool {
        return cache.object(forKey: key as NSString) != nil
    }
    
    func update(_ value: CacheType, forKey key: String) {
        cache.setObject(CacheWrapper(value: value), forKey: key as NSString)
    }
    
    func get(forKey key: String)-> CacheType? {
        cache.object(forKey: key as NSString)?.value
    }
    
    @discardableResult
    func removeValue(forKey key: String) -> CacheType? {
        if let value = cache.object(forKey: key as NSString) {
            cache.removeObject(forKey: key as NSString)
            return value.value
        }
        
        return nil
    }
    
    func clear() {
        cache.removeAllObjects()
    }
    
    var count: Int {
        return (cache.value(forKey: "allObjects") as? NSArray)?.count ?? 0
    }
}

