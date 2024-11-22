//
//  WMSRequesterPool.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

internal final class WMSRequesterPool: MapRequesterPool {
    private let semaphore = DispatchSemaphore(value: 1)
    static var shared: WMSRequesterPool = WMSRequesterPool()
    
    internal var tiles: [ImageTile] = []
    
    func contains(forKey key: String) -> Bool {
        defer { semaphore.signal() }
        semaphore.wait()
        
        return tiles.contains { tile in
            tile.key == key
        }
    }
    
    func enqueue(_ newElement: ImageTile) {
        defer { semaphore.signal() }
        semaphore.wait()
        tiles.append(newElement)
    }
    
    func dequeue() -> ImageTile? {
        defer { semaphore.signal() }
        semaphore.wait()
        
        if let _ = tiles.first {
            return tiles.removeFirst()
        }
        
        return nil
    }
}
