//
//  WMSTile.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

final public class TileWMS: SourceTile {
    public lazy var resolutions: ResolutionArray = {
        let extent = projection.tileExtent
        let maxResolution = max(extent.width / config.tileSize, extent.height / config.tileSize)
        
        let length = config.maxZoom + 1
        
        let resolutions = ResolutionArray()
        for i in 0..<length {
            resolutions.add(maxResolution / pow(2, Double(i)))
        }
        
        resolutions.sort()
        return resolutions
    }()
    public var config: any MapConfigurable
    public var projection: any Projection
    
    private let tileCache: TileCache = .init(capacity: 30)
    private var buffer: [String: any Tile] = [:]
    
    init(config: any MapConfigurable, projection: any Projection) {
        self.config = config
        self.projection = projection
    }
    
    
    public func getKey(_ coord: TileCoordinate) -> String {
        return "\(config.baseUrl)/\(coord.z)/\(coord.x)/\(coord.y)"
    }
    
    public func createTile(tileCoord: TileCoordinate, pixelRatio: Double) -> (any Tile)? {
        let tileCoord = wrapX(tileCoord: tileCoord)
        
        if withInExtendAndZ(tileCoord: tileCoord) {
            let tile = ImageTile(key: getKey(tileCoord), coordinate: tileCoord, url: "\(config.baseUrl)/\(getFixedTileURL(tileCoord, pixelRatio: pixelRatio))")
            
            return tile
        }
        return nil
    }
    
    public func getTile(_ z: Int, _ x: Int, _ y: Int, _ pixelRatio: Double) -> (any Tile)? {
        let coord = TileCoordinate(z: z, x: x, y: y)
        let tileKey = getKey(coord)
        
        if let tile = tileCache.get(forKey: tileKey) {
            return tile
        }
        
        if let tile = buffer[tileKey] {
            return tile
        }
        
        if let tile = createTile(tileCoord: coord, pixelRatio: pixelRatio) {
            buffer.updateValue(tile, forKey: tileKey)
            return tile
        }
        
        return nil
    }
    
    public func updateTile(forKey tileKey: String) -> (any Tile)? {
        if let tile = buffer.removeValue(forKey: tileKey) {
            tileCache.update(tile, forKey: tileKey)
            
            return tile
        }
        
        return nil
    }
    
    public func clear() {
        tileCache.clear()
        buffer.removeAll()
    }
    
    public func getFixedTileURL(_ coord: TileCoordinate, pixelRatio: Double) -> String {
        guard let tileExtent = getTileCoordExtent(coord) else { return "" }
        return getRequestParameters(coord, tileExtent)
    }
    
    private func getRequestParameters(_ coord: TileCoordinate, _ extent: MapExtent)-> String {
        var parameters = config.parameters
        parameters.updateValue(config.serviceType, forKey: "SERVICE")
        parameters.updateValue(config.version, forKey: "VERSION")
        parameters.updateValue(config.tileSize, forKey: "WIDTH")
        parameters.updateValue(config.tileSize, forKey: "HEIGHT")
        parameters.updateValue(config.requestType, forKey: "REQUEST")
        parameters.updateValue(config.format, forKey: "FORMAT")
        parameters.updateValue(projection.type.rawValue, forKey: "CRS")
        
        switch projection.type {
        case .epsg3857:
            parameters.updateValue("\(extent.minLongitude),\(extent.minLatitude),\(extent.maxLongitude),\(extent.maxLatitude)", forKey: "BBOX")
        case .epsg4326:
            parameters.updateValue("\(extent.minLatitude),\(extent.minLongitude),\(extent.maxLatitude),\(extent.maxLongitude)", forKey: "BBOX")
        }
        
        return parameters.urlQueryParameters
    }
}
