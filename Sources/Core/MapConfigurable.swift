//
//  WMSConfig.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

import Foundation

public enum TileMapServiceParameterType {
    case z_x_y
    case z_y_x
}

public enum MapServiceType {
    case wms
    case wmts
    case tms
}

public protocol MapConfigurable {
    var type: MapServiceType { get }
    
    var baseUrl: String { get }
    var corner: MapExtent.Corner { get }
    var initialZoom: Int { get }
    var tileSize: Double { get }
}

public struct WMSConfig: MapConfigurable {
    public let type: MapServiceType = .wms
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
    
    public init(baseUrl: String, version: String = "1.3.0", requestType: String, format: String = "image/png", minZoom: Int = 1, maxZoom: Int = 19, initialZoom: Int = 4, tileSize: Double = 256.0, corner: MapExtent.Corner = .topLeft, parameters: [String:Any] = [:]) {
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
    public let type: MapServiceType
    public let baseUrl: String
    public let corner: MapExtent.Corner
    public let tileSize: Double
    public let initialZoom: Int
    public let layer: TileMapServiceLayer
    public let parameterType: TileMapServiceParameterType
    public let apiKey: String?
    
    // WMTS일 경우 corner 값 topLeft.
    // WMTS의 경우 좌상단이 0,0이고 TMS의 경우 좌하단이 0,0
    // VWorld는 tms일 때, 좌상단을 bottomLeft로, OpenStreetMap은 tms일 때도 좌상단을 topLeft로 하네?
    public init(type: MapServiceType, baseUrl: String, initialZoom: Int, layer: TileMapServiceLayer, parameterType: TileMapServiceParameterType, corner: MapExtent.Corner = .topLeft, tileSize: Double = 256.0, apiKey: String? = nil) {
        self.type = type
        self.baseUrl = baseUrl
        self.initialZoom = initialZoom
        self.layer = layer
        self.parameterType = parameterType
        self.tileSize = tileSize
        self.apiKey = apiKey
        self.corner = corner
    }
}
