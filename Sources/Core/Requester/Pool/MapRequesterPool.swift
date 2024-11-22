//
//  MapRequesterPool.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

public protocol MapRequesterPool {
    associatedtype TileType: Tile
    
    static var shared: Self { get }
    var tiles: [TileType] { get }
    var count: Int { get }
    
    func enqueue(_ newElement: TileType)
    func dequeue()-> TileType?
    func contains(forKey key: String)-> Bool
}

public extension MapRequesterPool {
    var count: Int {
        return tiles.count
    }
}
