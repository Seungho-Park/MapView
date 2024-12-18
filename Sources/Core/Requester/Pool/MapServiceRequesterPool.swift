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
    
    private var _tiles: [ImageTile] = []
    internal var tiles: [ImageTile] {
        get { serialQueue.sync { return _tiles } }
        set { serialQueue.sync { _tiles = newValue } }
    }
    
    func contains(forKey key: String) -> Bool {
        return tiles.contains { tile in
            tile.key == key
        }
    }
    
    func enqueue(_ newElement: ImageTile) {
        tiles.append(newElement)
    }
    
    func dequeue() -> ImageTile? {
        if let _ = tiles.first {
            return tiles.removeFirst()
        }
            
        return nil
    }
}
