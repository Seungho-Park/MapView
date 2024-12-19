//
//  WMSTile.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation

final public class TileWMS: SourceTile {
    private let lock = NSLock()
    public lazy var resolutions: ResolutionArray = calculateResolutions()
    public var config: WMSConfig
    public var projection: any Projection
    public var minZoom: Int { return config.minZoom }
    public var maxZoom: Int { return config.maxZoom }
    
    private let tileCache: TileCache = TileCache.shared
    private var buffer: [String: any Tile] = [:]
    
    public init(config: WMSConfig, projection: any Projection = EPSG3857()) {
        self.config = config
        self.projection = projection
    }
    
    public func getKey(_ coord: TileCoordinate) -> String {
        return "\(config.baseUrl)/\(coord.z)/\(coord.x)/\(coord.y)"
    }
    
    public func createTile(tileCoord: TileCoordinate, pixelRatio: Double) -> (any Tile)? {
        let tileCoord = wrapX(tileCoord: tileCoord)
        
        if withInExtendAndZ(tileCoord: tileCoord) {
            let tile = ImageTile(key: getKey(tileCoord), coordinate: tileCoord, url: "\(getFixedTileURL(tileCoord, pixelRatio: pixelRatio))")
            
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
        
        lock.lock()
        defer { lock.unlock() }
        
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
        lock.lock()
        defer { lock.unlock() }
        if let tile = buffer.removeValue(forKey: tileKey) {
            tileCache.update(tile, forKey: tileKey)
            
            return tile
        }
        
        return nil
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        tileCache.clear()
        buffer.removeAll()
    }
    
    public func getFixedTileURL(_ coord: TileCoordinate, pixelRatio: Double) -> String {
        guard let tileExtent = getTileCoordExtent(coord) else { return "" }
        return "\(config.baseUrl)?\(getRequestParameters(coord, tileExtent))"
    }
    
    private func getRequestParameters(_ coord: TileCoordinate, _ extent: MapExtent)-> String {
        var parameters = config.parameters
        parameters.updateValue(config.serviceType, forKey: "SERVICE")
        parameters.updateValue(config.version, forKey: "VERSION")
        parameters.updateValue(String(format: "%.0f", config.tileSize), forKey: "WIDTH")
        parameters.updateValue(String(format: "%.0f", config.tileSize), forKey: "HEIGHT")
        parameters.updateValue(config.requestType, forKey: "REQUEST")
        parameters.updateValue(config.format, forKey: "FORMAT")
        parameters.updateValue(projection.type.rawValue, forKey: "CRS")
        
        switch projection.type {
        case .epsg3857:
            parameters.updateValue("\(extent.minLatitude),\(extent.minLongitude),\(extent.maxLatitude),\(extent.maxLongitude)", forKey: "BBOX")
        case .epsg4326:
            let minCoord = projection.convert(coord: .init(latitude: extent.minLatitude, longitude: extent.minLongitude), to: .epsg4326)
            let maxCoord = projection.convert(coord: .init(latitude: extent.maxLatitude, longitude: extent.maxLongitude), to: .epsg4326)
            
            parameters.updateValue("\(minCoord.latitude),\(minCoord.longitude),\(maxCoord.latitude),\(maxCoord.longitude)", forKey: "BBOX")
            
        }
        
        return parameters.urlQueryParameters
    }
}
