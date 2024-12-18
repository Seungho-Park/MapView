//
//  WMSRequesterPool.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

internal final class MapServiceRequesterPool: ServiceRequesterPool {
    private let lock = NSLock()
    static let shared: MapServiceRequesterPool = MapServiceRequesterPool()
    
    internal var tiles: [ImageTile] = []
    
    func contains(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return tiles.contains { tile in
            tile.key == key
        }
    }
    
    func enqueue(_ newElement: ImageTile) {
        lock.lock()
        defer { lock.unlock() }
        tiles.append(newElement)
    }
    
    func dequeue() -> ImageTile? {
        lock.lock()
        defer { lock.unlock() }
        if !tiles.isEmpty {
            return tiles.removeFirst()
        }
            
        return nil
    }
}
