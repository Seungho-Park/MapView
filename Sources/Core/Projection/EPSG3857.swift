//
//  EPSG3857.swift
//  MapView
//
//  Created by 박승호 on 11/23/24.
//

import Foundation

final class EPSG3857: Projection {
    var type: CoordinateSystem
    var tileExtent: MapExtent
    var worldExtent: MapExtent
    
    init(type: CoordinateSystem = .epsg3857) {
        self.type = type
        self.tileExtent = .init(minLongitude: -EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE, minLatitude: -EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE, maxLongitude: EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE, maxLatitude: EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE)
        self.worldExtent = .init(minLongitude: -180, minLatitude: -85, maxLongitude: 180, maxLatitude: 85)
    }
    
    func convert(coord: Coordinate, to: CoordinateSystem) -> Coordinate {
        switch to {
        case .epsg3857: return coord
        case .epsg4326:
            return Coordinate(
                latitude: 360 * atan(exp(coord.latitude / EPSG3857.EARTH_RADIUS)) / .pi - 90,
                longitude: 180 * coord.longitude / EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE
            )
        }
    }
    
    func from(coord: Coordinate, from: CoordinateSystem) -> Coordinate {
        switch from {
        case .epsg4326:
            let lon = EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE * coord.longitude / 180
            var lat = EPSG3857.EARTH_RADIUS * log(tan(.pi * (coord.latitude + 90) / 360))
            
            if lat > EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE {
                lat = EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE
            } else if lat < -EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE {
                lat = -EPSG3857.EARTH_CIRCUMFERENCE_HALF_SIZE
            }
            return Coordinate(latitude: lat, longitude: lon)
        case .epsg3857:
            return coord
        }
    }
}
