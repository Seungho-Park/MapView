//
//  MapView.swift
//  MapView
//
//  Created by 박승호 on 12/15/24.
//
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

internal enum MapState {
    case none
    case move(startPoint: CGPoint, currentPoint: CGPoint)
    case zoom(startDistance: Double, currentDistance: Double?)
}

#if canImport(UIKit)
public typealias MapPlatformView = UIView
#elseif canImport(AppKit)
public typealias MapPlatformView = NSView
#endif

open class MapView: MapPlatformView {
    private var mapLayer: (any TileLayer)!
    internal var mapState: MapState = .none
    private let lonlatToPixelTransform = Transform()
    private let pixelToLonlatTransform = Transform()
    
    private let zoomFactor = 2.0
    private var resolution: Double = .zero
    private var centerCoord: Coordinate = .init(latitude: 4519089.62003392, longitude: 14134945.162872873)
    private var zoom: Int = 7
    private var angle: Double = 0
    private var isAvailableRotate: Bool = false
    
    public convenience init(map: any SourceTile) {
        self.init(frame: .zero)
        
        mapLayer = ImageTileLayer(source: map)
        self.zoom = map.config.initialZoom
        mapLayer.mapDelegate = self
        
        commit()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
        
        #if canImport(UIKit)
        self.contentMode = .redraw
        #elseif canImport(AppKit)
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.delegate = self
        #endif
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commit() {
        mapLayer.isOpaque = false
        
        invalidate()
    }
    
    #if canImport(UIKit)
    open override func draw(_ layer: CALayer, in ctx: CGContext) {
        render(layer, context: ctx)
    }
    #endif
    
    private func render(_ layer: CALayer?, context: CGContext) {
        guard let layer else { return }
        context.saveGState()
        switch mapState {
        case .move(let downPoint, let movePoint):
            let moveX = movePoint.x - downPoint.x
            
            #if !os(macOS)
            let moveY = movePoint.y - downPoint.y
            #else
            let moveY = downPoint.y - movePoint.y
            #endif
            
            context.translateBy(x: moveX, y: moveY)
        case .zoom(let startDistance, let moveDistance):
            guard let moveDistance = moveDistance else { break }
            let scaleRate = max(0.5, min(moveDistance / startDistance, 2.0))
            
            context.translateBy(x: layer.frame.midX, y: layer.frame.midY)
            context.scaleBy(x: scaleRate, y: scaleRate)
            context.translateBy(x: -layer.frame.midX, y: -layer.frame.midY)
        case .none:
            apply()
            renderFrame()
        }
        
        mapLayer.render(in: context)
        context.restoreGState()
    }
    
    func worldToPixel(coord: Coordinate)-> CGPoint {
        return .init(
            x: (lonlatToPixelTransform.get(0) * coord.longitude) + (lonlatToPixelTransform.get(2) * coord.latitude) + lonlatToPixelTransform.get(4),
            y: (lonlatToPixelTransform.get(1) * coord.longitude) + (lonlatToPixelTransform.get(3) * coord.latitude) + lonlatToPixelTransform.get(5)
        )
    }
    
    func pixelToWorld(point: CGPoint) -> Coordinate {
        return .init(
            latitude: pixelToLonlatTransform.get(1) * point.x + pixelToLonlatTransform.get(3) * point.y + pixelToLonlatTransform.get(5),
            longitude: pixelToLonlatTransform.get(0) * point.x + pixelToLonlatTransform.get(2) * point.y + pixelToLonlatTransform.get(4)
        )
    }
    
    func lonlatToPixel(coord: Coordinate) -> CGPoint {
        let coord = mapLayer.source.projection.convert(coord: coord, to: .epsg3857)
        let point = worldToPixel(coord: coord)
        
        return .init(x: point.x, y: point.y)
    }
    
    func zoomIn() {
        let newZoom = zoom + 1
        if newZoom <= mapLayer.source.maxZoom {
            zoom = newZoom
            apply()
            renderFrame()
        }
        
        invalidate()
    }
    
    func zoomOut() {
        let newZoom = zoom - 1
        if newZoom >= mapLayer.source.minZoom {
            zoom = newZoom
            apply()
            renderFrame()
        }
        
        invalidate()
    }
    
    private func apply() {
        let extent = mapLayer.source.extent
        let size = max(extent.width, extent.height)
        let maxResolution = size / mapLayer.source.config.tileSize / pow(2, 0)
        
        resolution = createSnapToPower(delta:Int(zoom - mapLayer.source.minZoom), resolution: maxResolution / pow(zoomFactor, Double(mapLayer.source.minZoom)), direction: 0)
    }
    
    private func renderFrame() {
        mapLayer.prepareFrame(screenSize: self.bounds.size, center: centerCoord, resolution: resolution, angle: angle, extent: getScreenExtent(size: self.bounds.size))
        
        lonlatToPixelTransform.composite(self.bounds.size.width / 2, self.bounds.size.height / 2, -centerCoord.longitude, -centerCoord.latitude, 1 / resolution, -1 / resolution, angle)
        pixelToLonlatTransform.inverse(transform: lonlatToPixelTransform)
    }
    
    private func getScreenExtent(size: CGSize)-> MapExtent {
        let newSize = isAvailableRotate ? CGSize(width: sqrt(size.width * size.width + size.height * size.height), height: sqrt(size.width * size.width + size.height * size.height)) : size
        
        let x = resolution * size.width / 2
        let y = resolution * size.height / 2
        
        let cosRotation = cos(angle * .pi / 180)
        let sinRotation = sin(angle * .pi / 180)

        let xCos = x * cosRotation
        let xSin = x * sinRotation
        let yCos = y * cosRotation
        let ySin = y * sinRotation
        
        let x0 = centerCoord.longitude - xCos + ySin
        let x1 = centerCoord.longitude - xCos - ySin
        let x2 = centerCoord.longitude + xCos - ySin
        let x3 = centerCoord.longitude + xCos + ySin
        
        let y0 = centerCoord.latitude - xSin - yCos
        let y1 = centerCoord.latitude - xSin + yCos
        let y2 = centerCoord.latitude + xSin + yCos
        let y3 = centerCoord.latitude + xSin - yCos
        
        return .init(
            minLongitude: min(min(x0, x1), min(x2, x3)),
            minLatitude: min(min(y0, y1), min(y2, y3)),
            maxLongitude: max(max(x0, x1), max(x2, x3)),
            maxLatitude: max(max(y0, y1), max(y2, y3))
        )
    }
    
    private func createSnapToPower(delta: Int, resolution: Double, direction: Int)-> Double {
        let offset = Double(-direction / 2) + 0.5
        let oldLevel = Int(floor(log(resolution/resolution) / log(zoomFactor + offset)))
        let newLevel = max(oldLevel + delta, 0)
        return resolution / pow(zoomFactor, Double(newLevel))
    }
    
    func invalidate() {
        #if !os(macOS)
        self.layer.setNeedsDisplay()
        #else
        self.layer?.setNeedsDisplay()
        #endif
    }
}

// MARK: - Touch Event
internal extension MapView {
    // MARK: - Handle Methods
    internal func calculateDistance(between point1: CGPoint, and point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    internal func isMoveMapAction(from point1: CGPoint, to point2: CGPoint, threshold: CGFloat = 5) -> Bool {
        return calculateDistance(between: point1, and: point2) > threshold
    }
    
    internal func handleMoveMap(from startPoint: CGPoint, to endPoint: CGPoint) {
        let deltaX = endPoint.x - startPoint.x
        
        #if !os(macOS)
        let deltaY = endPoint.y - startPoint.y
        #else
        let deltaY = startPoint.y - endPoint.y
        #endif
        
        var centerXY = worldToPixel(coord: centerCoord)
        centerXY.x -= deltaX
        centerXY.y -= deltaY
        
        centerCoord = pixelToWorld(point: centerXY)
        renderFrame()
        invalidate()
    }
    
    internal func handleZoom(with scaleRate: Double) {
        if scaleRate > 1 {
            zoomIn()
        } else if scaleRate < 1 {
            zoomOut()
        }
    }
}

#if canImport(AppKit)
extension MapView: CALayerDelegate {
    open override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.needsDisplayOnBoundsChange = true
        layer.delegate = self
        return layer
    }
    
    public func draw(_ layer: CALayer, in ctx: CGContext) {
        render(layer, context: ctx)
    }
}
#endif

extension MapView: TileLayerDelegate {
    public func refreshLayer() {
        DispatchQueue.main.async {
            self.invalidate()
        }
    }
}
