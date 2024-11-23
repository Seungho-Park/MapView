//
//  WMSConfig.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

import Foundation

public protocol MapConfigurable {
    var baseUrl: String { get }
    var minZoom: Int { get }
    var maxZoom: Int { get }
    var corner: MapExtent.Corner { get }
    var initialZoom: Int { get }
    var tileSize: Double { get }
}

public struct MapConfig: MapConfigurable {
    public let baseUrl: String
    public let minZoom: Int
    public let maxZoom: Int
    public let initialZoom: Int
    public let tileSize: Double
    public let corner: MapExtent.Corner
    
    public init(baseUrl: String, minZoom: Int = 7, maxZoom: Int = 19, initialZoom: Int = 7, tileSize: Double = 256.0, corner: MapExtent.Corner = .topLeft) {
        self.baseUrl = baseUrl
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.initialZoom = initialZoom
        self.tileSize = tileSize
        self.corner = corner
    }
}
