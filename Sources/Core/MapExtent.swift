//
//  MapExtent.swift
//  WMSView
//
//  Created by 박승호 on 11/19/24.
//

public extension MapExtent {
    enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

public struct MapExtent {
    let minLongitude: Double
    let minLatitude: Double
    let maxLongitude: Double
    let maxLatitude: Double
    
    var width: Double {
        maxLongitude - minLongitude
    }
    
    var height: Double {
        maxLatitude - minLatitude
    }
    
    func get(_ corner: MapExtent.Corner)-> Coordinate {
        switch corner {
        case .topLeft:
            return .init(latitude: maxLatitude, longitude: minLongitude)
        case .topRight:
            return .init(latitude: maxLatitude, longitude: maxLongitude)
        case .bottomLeft:
            return .init(latitude: minLatitude, longitude: minLongitude)
        case .bottomRight:
            return .init(latitude: minLatitude, longitude: maxLongitude)
        }
    }
    
    func contains(_ coord: Coordinate)-> Bool {
        return (minLongitude <= coord.longitude) && (maxLongitude >= coord.longitude) && (minLatitude <= coord.latitude) && (maxLatitude >= coord.latitude)
    }
    
    func joined(_ separator: String)-> String {
        return "\(minLongitude)\(separator)\(minLatitude)\(separator)\(maxLongitude)\(separator)\(maxLatitude)"
    }
}
