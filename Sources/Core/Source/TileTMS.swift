//
//  TileTMS.swift
//  MapView
//
//  Created by 박승호 on 12/16/24.
//
import Foundation

public protocol TileMapServiceLayer {
    var layer: String { get }
    var minZoom: Int { get }
    var maxZoom: Int { get }
    var tileType: String { get }
}

final public class TileTMS: SourceTile {
    private let lock = NSLock()
    private let tileCache = TileCache.shared
    private var tileBuffer: [String: any Tile] = [:]
    private var layerType: TileMapServiceLayer!
    
    public let config: TileMapServiceConfig
    public var projection: any Projection
    public lazy var resolutions: ResolutionArray = calculateResolutions()
    
    public var minZoom: Int { return layerType.minZoom }
    public var maxZoom: Int { return layerType.maxZoom }
    
    public init(config: TileMapServiceConfig, projection: any Projection = EPSG3857()) {
        self.config = config
        self.projection = projection
        self.layerType = config.layer
    }
    
    public func getKey(_ coord: TileCoordinate) -> String {
        return "\(config.baseUrl)/\(coord.z)/\(coord.x)/\(coord.y)"
    }
    
    public func createTile(tileCoord: TileCoordinate, pixelRatio: Double) -> (any Tile)? {
        let tileCoord = wrapX(tileCoord: tileCoord)
        if withInExtendAndZ(tileCoord: tileCoord) {
            return ImageTile(key: getKey(tileCoord), coordinate: tileCoord, url: "\(config.baseUrl)/\(getFixedTileURL(tileCoord, pixelRatio: pixelRatio))")
        }
        
        return nil
    }
    
    public func getTile(_ z: Int, _ x: Int, _ y: Int, _ pixelRatio: Double) -> (any Tile)? {
        let coord = TileCoordinate(z: z, x: x, y: y)
        let tileKey = getKey(coord)
        
        if let tile = tileCache.get(forKey: tileKey) {
            return tile
        }
        
        lock.lock()
        defer { lock.unlock() }
        if let tile = tileBuffer[tileKey] {
            return tile
        }
        
        if let tile = createTile(tileCoord: coord, pixelRatio: pixelRatio) {
            tileBuffer.updateValue(tile, forKey: tileKey)
        }
        
        return nil
    }
    
    public func updateTile(forKey tileKey: String) -> (any Tile)? {
        lock.lock()
        defer { lock.unlock() }
        if let tile = tileBuffer.removeValue(forKey: tileKey) {
            tileCache.update(tile, forKey: tileKey)
            return tile
        }
        
        return nil
    }
    
    public func clear() {
        tileCache.clear()
        tileBuffer.removeAll()
    }
    
    //VWorld일 때는 {z}/{y}/{x}.확장자
    //OpenStreetMap은 {z}/{x}/{y}인데...
    public func getFixedTileURL(_ coord: TileCoordinate, pixelRatio: Double) -> String {
        var parameters: String = config.apiKey != nil ? "\(config.apiKey!)/" : ""
        if !layerType.layer.isEmpty {
            parameters += "\(layerType.layer)/"
        }
        parameters += "\(abs(coord.z))/"
        
        switch config.parameterType {
        case .z_x_y:
            parameters += "\(coord.x < 0 ? abs(coord.x + 1) : coord.x)/"
            parameters += "\(coord.y < 0 ? abs(coord.y + 1) : coord.y)"
        case .z_y_x:
            parameters += "\(coord.y < 0 ? abs(coord.y + 1) : coord.y)/"
            parameters += "\(coord.x < 0 ? abs(coord.x + 1) : coord.x)"
        }
        parameters += ".\(layerType.tileType)"
        return parameters
    }
}
