//
//  EPSG4326.swift
//  WMSView
//
//  Created by 박승호 on 12/15/24.
//
import Foundation

final public class EPSG4326: Projection {
    public var type: CoordinateSystem = .epsg4326
    public var tileExtent: MapExtent
    public var worldExtent: MapExtent
    
    public init() {
        self.tileExtent = .init(minLongitude: -180, minLatitude: -90, maxLongitude: 180, maxLatitude: 90)
        self.worldExtent = .init(minLongitude: -180, minLatitude: -90, maxLongitude: 180, maxLatitude: 90)
    }
    
    public func convert(coord: Coordinate, to: CoordinateSystem) -> Coordinate {
        switch to {
        case .epsg3857:
            let lon = EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE * coord.longitude / 180
            var lat = EPSG4326.EARTH_RADIUS * log(tan(.pi * (coord.latitude + 90) / 360))
            
            if lat > EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE {
                lat = EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE
            } else if lat < -EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE {
                lat = -EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE
            }
            
            return Coordinate(latitude: lat, longitude: lon)
        case .epsg4326:
            return coord
        }
    }
    
    public func from(coord: Coordinate, from: CoordinateSystem) -> Coordinate {
        switch from {
        case .epsg4326:
            return coord
        case .epsg3857:
            return Coordinate(latitude: 360 * atan(exp(coord.latitude / EPSG4326.EARTH_RADIUS)) / .pi - 90, longitude: 180 * coord.longitude / EPSG4326.EARTH_CIRCUMFERENCE_HALF_SIZE)
        }
    }
}
