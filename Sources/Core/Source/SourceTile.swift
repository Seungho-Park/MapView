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
    
    public func getZForResolution(resolution: Double, direction: Int)-> Int? {
        guard let z = resolutions.findNearest(value: resolution, direction: direction) else { return nil }
        return z.clamp(config.minZoom, config.maxZoom)
    }
}

public extension SourceTile {
    var extent: MapExtent {
        return projection.tileExtent
    }
    
    var origin: Coordinate {
        return extent.get(config.corner)
    }
}
