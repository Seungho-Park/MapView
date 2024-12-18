//
//  Tile.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

public enum TileState {
    case idle, loading, loaded, error, empty, abort
}

public protocol Tile {
    associatedtype TileData
    
    var key: String { get }
    var coordinate: TileCoordinate { get }
    var url: String { get }
    var tileState: TileState { get set }
    var tileData: TileData? { get set }
    
    func load(completion: @escaping (Bool)-> Void)
    func load() async -> Bool
}
