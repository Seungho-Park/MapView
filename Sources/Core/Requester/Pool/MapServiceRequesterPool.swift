//
//  WMSRequesterPool.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

internal final class MapServiceRequesterPool: ServiceRequesterPool {
    private let serialQueue: DispatchQueue = .init(label: "MapServiceRequesterPool", qos: .background)
    static var shared: MapServiceRequesterPool = MapServiceRequesterPool()
    
    internal var tiles: [ImageTile] = []
    
    func contains(forKey key: String) -> Bool {
        serialQueue.sync {
            return tiles.contains { tile in
                tile.key == key
            }
        }
    }
    
    func enqueue(_ newElement: ImageTile) {
        serialQueue.sync {
            tiles.append(newElement)
        }
    }
    
    func dequeue() -> ImageTile? {
        serialQueue.sync {
            if let _ = tiles.first {
                return tiles.removeFirst()
            }
            
            return nil
        }
    }
}
