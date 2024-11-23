//
//  Projection.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

import Foundation

public enum CoordinateSystem: String {
    case epsg3857 = "EPSG:3857"
    case epsg4326 = "EPSG:4326"
}

public protocol Projection {
    var type: CoordinateSystem { get }
    var tileExtent: MapExtent { get }
    var worldExtent: MapExtent { get }
    
    func convert(coord: Coordinate, to: CoordinateSystem)-> Coordinate
    func from(coord: Coordinate, from: CoordinateSystem)-> Coordinate
}

public extension Projection {
    static var EARTH_RADIUS: Double {
        return 6378137.0
    }
    
    static var EARTH_CIRCUMFERENCE_HALF_SIZE: Double {
        .pi * EARTH_RADIUS
    }
}
