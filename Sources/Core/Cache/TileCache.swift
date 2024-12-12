//
//  TileCache.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

import Foundation

final class TileCache: MapCache {
    static let shared = TileCache(capacity: 100)
    
    var cache: NSCache<NSString, CacheWrapper<any Tile>>
    var capacity: Int {
        get {
            return cache.countLimit
        }
        set {
            cache.countLimit = newValue
        }
    }
    
    init(capacity: Int) {
        cache = .init()
        cache.countLimit = capacity
    }
}
