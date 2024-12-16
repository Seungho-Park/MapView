//
//  WMSConfig.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

import Foundation

public protocol MapConfigurable {
    var baseUrl: String { get }
    var corner: MapExtent.Corner { get }
    var initialZoom: Int { get }
    var tileSize: Double { get }
}

public struct WMSConfig: MapConfigurable {
    public let baseUrl: String
    public let minZoom: Int
    public let maxZoom: Int
    public let initialZoom: Int
    public let tileSize: Double
    public let corner: MapExtent.Corner
    public let serviceType: String = "WMS"
    public let version: String
    public let requestType: String
    public let format: String
    public let parameters: [String : Any]
    
    public init(baseUrl: String, version: String = "1.3.0", requestType: String, format: String = "image/png", minZoom: Int = 5, maxZoom: Int = 19, initialZoom: Int = 7, tileSize: Double = 256.0, corner: MapExtent.Corner = .topLeft, parameters: [String:Any] = [:]) {
        self.baseUrl = baseUrl
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.initialZoom = initialZoom
        self.tileSize = tileSize
        self.corner = corner
        self.version = version
        self.requestType = requestType
        self.format = format
        self.parameters = parameters
    }
}

public struct TileMapServiceConfig: MapConfigurable {
    public let baseUrl: String
    public let corner: MapExtent.Corner
    public let tileSize: Double
    public let initialZoom: Int
    public let layer: TileMapServiceLayer
    public let apiKey: String?
    
    // WMTS일 경우 corner 값 topLeft.
    // WMTS의 경우 좌상단이 0,0이고 TMS의 경우 좌하단이 0,0
    public init(baseUrl: String, corner: MapExtent.Corner = .topLeft, initialZoom: Int, layer: TileMapServiceLayer, tileSize: Double = 256.0, apiKey: String? = nil) {
        self.baseUrl = baseUrl
        self.initialZoom = initialZoom
        self.layer = layer
        self.tileSize = tileSize
        self.apiKey = apiKey
        self.corner = corner
    }
}
