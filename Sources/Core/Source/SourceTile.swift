//
//  SourceTile.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

import Foundation

public protocol SourceTile {
    associatedtype Config: MapConfigurable
    
    var projection: Projection { get }
    var resolutions: ResolutionArray { get }
    var config: Config { get }
    var minZoom: Int { get }
    var maxZoom: Int { get }
    
    func getKey(_ coord: TileCoordinate)-> String
    func createTile(tileCoord: TileCoordinate, pixelRatio: Double)-> (any Tile)?
    func getTile(_ z: Int, _ x: Int, _ y: Int, _ pixelRatio: Double)-> (any Tile)?
    func updateTile(forKey tileKey: String)-> (any Tile)?
    func clear()
    
    func getFixedTileURL(_ coord: TileCoordinate, pixelRatio: Double)-> String
}

public extension SourceTile {
    var extent: MapExtent {
        return projection.tileExtent
    }
    
    var origin: Coordinate {
        return extent.get(config.corner)
    }
    
    func getZForResolution(resolution: Double, direction: Int)-> Int? {
        guard let z = resolutions.findNearest(value: resolution, direction: direction) else { return nil }
        return z.clamp(minZoom, maxZoom)
    }
    
    private func getIndexForResolution(resolution: Double, direction: Int)-> Int? {
        guard let index = resolutions.findNearest(value: resolution, direction: direction) else { return nil }
        return index.clamp(minZoom, maxZoom)
    }
    
    internal func wrapX(tileCoord: TileCoordinate)-> TileCoordinate {
        guard var center = getCenterForTileCoordinate(tileCoord: tileCoord),
              !extent.contains(center),
              let resolution = resolutions.get(tileCoord.z)
        else { return tileCoord }
        
        let worldWidth = extent.width
        let worldAway = ceil((extent.minLongitude - center.longitude) / worldWidth)
        
        center.longitude = center.longitude + (worldWidth * worldAway)
        
        return getTileCoordForXYAndResolution(coord: center, resolution: resolution, reverseIntersectionPolicy: false) ?? tileCoord
    }
    
    internal func getCenterForTileCoordinate(tileCoord: TileCoordinate)-> Coordinate? {
        guard let resolution = resolutions.get(tileCoord.z) else {
            return nil
        }
        
        return .init(
            latitude: origin.latitude + (Double(tileCoord.y) + 0.5) * config.tileSize * resolution,
            longitude: origin.longitude + (Double(tileCoord.x) + 0.5) * config.tileSize * resolution
        )
    }
    
    internal func withInExtendAndZ(tileCoord: TileCoordinate) -> Bool {
        if minZoom > tileCoord.z || tileCoord.z > maxZoom {
            return false
        }
        
        let tileRange = getTileRangeForExtentAndZ(extent: extent, z: tileCoord.z)
        return tileRange?.contains(tileCoord.x, tileCoord.y) ?? false
    }
    
    internal func getTileRangeForExtentAndZ(extent: MapExtent, z: Int)-> TileRange? {
        guard let resolution = resolutions.get(z) else { return nil }
        return getTileRangeForExtentAndResolution(extent: extent, resolution: resolution)
    }
    
    private func getTileCoordForXYAndResolution(coord: Coordinate, resolution: Double, reverseIntersectionPolicy: Bool)-> TileCoordinate? {
        guard let index = getIndexForResolution(resolution: resolution, direction: 0),
              let resolutionScale = resolutions.get(index)
        else {
            return nil
        }
        
        let scale = resolution / resolutionScale
        
        let adjustX: Double = reverseIntersectionPolicy ? 0.5 : 0
        let adjustY: Double = reverseIntersectionPolicy ? 0 : 0.5
        
        let xFromOrigin = floor((coord.longitude - origin.longitude) / resolution + adjustX)
        let yFromOrigin = floor((coord.latitude - origin.latitude) / resolution + adjustY)
        
        let x = scale * xFromOrigin / config.tileSize
        let y = scale * yFromOrigin / config.tileSize
        
        return reverseIntersectionPolicy ?
            .init(z: index, x: Int(ceil(x) - 1), y: Int(ceil(y) - 1)) :
            .init(z: index, x: Int(floor(x)), y: Int(floor(y)))
    }
    
    internal func getTileRangeForExtentAndResolution(extent: MapExtent, resolution: Double)-> TileRange? {
        guard let minTileCoord = getTileCoordForXYAndResolution(coord: extent.get(.bottomLeft), resolution: resolution, reverseIntersectionPolicy: false),
              let maxTileCoord = getTileCoordForXYAndResolution(coord: extent.get(.topRight), resolution: resolution, reverseIntersectionPolicy: true)
        else {
            return nil
        }
        
        return TileRange(minX: minTileCoord.x, minY: minTileCoord.y, maxX: maxTileCoord.x, maxY: maxTileCoord.y)
    }
    
    internal func getTileCoordExtent(_ tileCoord: TileCoordinate)-> MapExtent? {
        guard let resolution = resolutions.get(tileCoord.z) else { return nil }
        
        let minLongitude = origin.longitude + (Double(tileCoord.x) * config.tileSize * resolution)
        let minLatitude = origin.latitude + (Double(tileCoord.y) * config.tileSize * resolution)
        
        return .init(minLongitude: minLongitude, minLatitude: minLatitude, maxLongitude: minLongitude + (config.tileSize * resolution), maxLatitude: minLatitude + (config.tileSize * resolution))
    }
    
    internal func getResolution(_ z: Int)-> Double? {
        return resolutions.get(z)
    }
    
    internal func getExtentForTileRange(z: Int, tileRange: TileRange)-> MapExtent? {
        guard let resolution = resolutions.get(z) else { return nil }
        
        return MapExtent(
            minLongitude: origin.longitude + Double(tileRange.minX) * config.tileSize * resolution,
            minLatitude: origin.latitude + Double(tileRange.minY) * config.tileSize * resolution,
            maxLongitude: origin.longitude + Double(tileRange.maxX + 1) * config.tileSize * resolution,
            maxLatitude: origin.latitude + Double(tileRange.maxY + 1) * config.tileSize * resolution
        )
    }
    
    internal func calculateResolutions() -> ResolutionArray {
        let extent = projection.tileExtent
        let maxResolution = max(extent.width / config.tileSize, extent.height / config.tileSize)
        
        let length = maxZoom + 1
        let resolutions = ResolutionArray()
        
        for i in 0..<length {
            resolutions.add(maxResolution / pow(2, Double(i)))
        }
        resolutions.sort()
        return resolutions
    }
}
