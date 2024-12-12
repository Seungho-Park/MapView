//
//  TileRange.swift
//  MapView
//
//  Created by 박승호 on 12/12/24.
//

internal struct TileRange {
    let minX: Int
    let minY: Int
    let maxX: Int
    let maxY: Int
    
    var width: Int {
        return maxX - minX + 1
    }
    
    var height: Int {
        return maxY - minY + 1
    }
    
    func contains(_ x: Int, _ y: Int)-> Bool {
        return (minX <= x) && (x <= maxX) && (minY <= y) && (y <= maxY)
    }
}
