//
//  TileGrid.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

public protocol TileGrid {
    var minZoom: Int { get }
    var maxZoom: Int { get }
}

internal final class DefaultTileGrid: TileGrid {
    var minZoom: Int
    var maxZoom: Int
    
    init(minZoom: Int, maxZoom: Int) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
}
