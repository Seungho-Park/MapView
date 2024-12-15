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
    var serviceType: String { get }
    var version: String { get }
    var requestType: String { get }
    var format: String { get }
    var parameters: [String: Any] { get }
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
    public var parameters: [String : Any]
    
    public init(baseUrl: String, version: String = "1.3.0", requestType: String, format: String = "image/png", minZoom: Int = 9, maxZoom: Int = 19, initialZoom: Int = 9, tileSize: Double = 256.0, corner: MapExtent.Corner = .topLeft, parameters: [String:Any] = [:]) {
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
