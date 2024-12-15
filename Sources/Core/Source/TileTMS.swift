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
    private let tileCache = TileCache.shared
    private var tileBuffer: [String: any Tile] = [:]
    private var layerType: TileMapServiceLayer!
    
    public let config: TileMapServiceConfig
    public var projection: any Projection
    public lazy var resolutions: ResolutionArray = {
        let extent = projection.tileExtent
        let maxResolution = max(extent.width / config.tileSize, extent.height / config.tileSize)
        
        let length = maxZoom + 1
        
        let resolutions = ResolutionArray()
        for i in 0..<length {
            resolutions.add(maxResolution / pow(2, Double(i)))
        }
        
        resolutions.sort()
        return resolutions
    }()
    
    public var minZoom: Int { return layerType.minZoom }
    public var maxZoom: Int { return layerType.maxZoom }
    
    public init(config: TileMapServiceConfig, projection: any Projection) {
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
        if let tile = tileCache.get(forKey: tileKey) ?? tileBuffer[tileKey] ?? createTile(tileCoord: coord, pixelRatio: pixelRatio) {
            tileBuffer.updateValue(tile, forKey: tileKey)
            return tile
        }
        
        return nil
    }
    
    public func updateTile(forKey tileKey: String) -> (any Tile)? {
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
    
    public func getFixedTileURL(_ coord: TileCoordinate, pixelRatio: Double) -> String {
        var parameters: String = config.apiKey != nil ? "\(config.apiKey!)/" : ""
        parameters += "\(layerType.layer)/"
        parameters += "\(abs(coord.z))/"
        parameters += "\(coord.y < 0 ? abs(coord.y + 1) : coord.y)/"
        parameters += "\(coord.x < 0 ? abs(coord.x + 1) : coord.x)"
        parameters += ".\(layerType.tileType)"
        return parameters
    }
}
