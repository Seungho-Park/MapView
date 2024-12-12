//
//  SourceTile.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

import Foundation

open class SourceTile {
    private lazy var resolutions: ResolutionArray = {
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
    
    internal let projection: Projection
    internal let config: MapConfigurable
    
    init(config: MapConfigurable) {
        self.config = config
        self.projection = EPSG3857()
    }
    
    func createTile(tileCoordinate: TileCoordinate)-> (any Tile)? {
        guard let tileCoord = wrapX(tileCoord: tileCoordinate) else {
            return nil
        }
        
        
        return nil
    }
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
        return z.clamp(config.minZoom, config.maxZoom)
    }
    
    private func getTileCoordForXYAndResolution(lon: Double, lat: Double, resolution: Double, reverseIntersectionPolicy: Bool)-> TileCoordinate? {
        guard let index = getIndexForResolution(resolution: resolution, direction: 0),
              let resolutionScale = resolutions.get(index) else {
            return nil
        }
        
        return nil
    }
    
    private func getIndexForResolution(resolution: Double, direction: Int)-> Int? {
        guard let index = resolutions.findNearest(value: resolution, direction: direction) else { return nil }
        return index.clamp(config.minZoom, config.maxZoom)
    }
    
    private func wrapX(tileCoord: TileCoordinate)-> TileCoordinate? {
        
        return tileCoord
    }
    
    private func withInExtendAndZ(tileCoord: TileCoordinate) -> Bool {
        if config.minZoom > tileCoord.z || tileCoord.z > config.maxZoom {
            return false
        }
        
        return false
    }
    
    private func getTileRangeForExtentAndZ(extent: MapExtent, z: Int) {
        guard let resolution = resolutions.get(z) else { return }
    }
}
