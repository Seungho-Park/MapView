//
//  ImageTile.swift
//  MapView
//
//  Created by 박승호 on 11/19/24.
//
import Foundation

public final class ImageTile: Tile {
    
    public var key: String
    public var coordinate: TileCoordinate
    public var url: String
    public var tileState: TileState
    public var tileData: Data?
    
    public init(key: String, coordinate: TileCoordinate, url: String, tileState: TileState, tileData: Data? = nil) {
        self.key = key
        self.coordinate = coordinate
        self.url = url
        self.tileState = tileState
        self.tileData = tileData
    }
    
    public func load() {
        guard let url = URL(string: url),
              let data = try? Data(contentsOf: url)
        else {
            tileState = .error
            tileData = nil
            return
        }
        
        tileState = .loaded
        tileData = data
    }
}
