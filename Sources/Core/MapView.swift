//
//  MapView.swift
//  MapView
//
//  Created by 박승호 on 12/15/24.
//
import Foundation
import UIKit

internal enum MapState {
    case none
    case move(startPoint: CGPoint, currentPoint: CGPoint)
    case zoom(startDistance: Double, currentDistance: Double?)
}

open class MapView: UIView {
    private var mapLayer: (any TileLayer)!
    private var mapState: MapState = .none
    private let lonlatToPixelTransform = Transform()
    private let pixelToLonlatTransform = Transform()
    
    private let zoomFactor = 2.0
    private var resolution: Double = .zero
    private var centerCoord: Coordinate = .init(latitude: 4519089.62003392, longitude: 14134945.162872873)
    private var zoom: Int = 7
    private var angle: Double = 0
    private var isAvailableRotate: Bool = false
    
    public convenience init(config: MapConfigurable) {
        self.init(frame: .zero)
        
        if let config = config as? WMSConfig {
            mapLayer = ImageTileLayer(source: TileWMS(config: config))
        } else if let config = config as? TileMapServiceConfig {
            mapLayer = ImageTileLayer(source: TileTMS(config: config, projection: EPSG3857()))
        }
        
        self.zoom = config.initialZoom
        mapLayer.mapDelegate = self
        
        commit()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .redraw
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commit() {
        mapLayer.isOpaque = false
        
        self.layer.addSublayer(mapLayer)
    }
    
    open override func draw(_ layer: CALayer, in ctx: CGContext) {
        ctx.clear(layer.frame)
        
        switch mapState {
        case .move(let downPoint, let movePoint):
            let moveX = movePoint.x - downPoint.x
            let moveY = movePoint.y - downPoint.y
            
            ctx.saveGState()
            ctx.translateBy(x: moveX, y: moveY)
            mapLayer.render(in: ctx)
            ctx.restoreGState()
        case .zoom(let startDistance, let moveDistance):
            guard let moveDistance = moveDistance else { break }
            let scaleRate = max(0.5, min(moveDistance / startDistance, 2.0))
            
            ctx.saveGState()
            ctx.translateBy(x: layer.frame.midX, y: layer.frame.midY)
            ctx.scaleBy(x: scaleRate, y: scaleRate)
            ctx.translateBy(x: -layer.frame.midX, y: -layer.frame.midY)
            mapLayer.render(in: ctx)
            ctx.restoreGState()
        case .none:
            apply()
            renderFrame()
            
            ctx.saveGState()
            mapLayer.render(in: ctx)
            ctx.restoreGState()
        }
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
        
        self.layer.setNeedsDisplay()
    }
    
    func zoomOut() {
        let newZoom = zoom - 1
        if newZoom >= mapLayer.source.minZoom {
            zoom = newZoom
            apply()
            renderFrame()
        }
        
        self.layer.setNeedsDisplay()
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
}

// MARK: - Touch Event
public extension MapView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        if allTouches.count == 1 {
            mapState = .move(startPoint: touchPoints[0], currentPoint: touchPoints[0])
        } else {
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .zoom(startDistance: distance, currentDistance: nil)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        switch mapState {
        case .none:
            break
        case .move(let startPoint, let currentPoint):
            if allTouches.count > 1 {
                let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
                mapState = .zoom(startDistance: distance, currentDistance: distance)
            } else {
                let newPoint = touchPoints[0]
                if isMoveMapAction(from: currentPoint, to: newPoint) {
                    mapState = .move(startPoint: startPoint, currentPoint: newPoint)
                    self.layer.setNeedsDisplay()
                }
            }
        case .zoom(let startDistance, _):
            guard touchPoints.count == 2 else { break }
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .zoom(startDistance: startDistance, currentDistance: distance)
            self.layer.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        switch mapState {
        case .none:
            break
        case .move(let startPoint, _):
            guard allTouches.count == 1 else { break }
            let endPoint = touchPoints[0]
            
            if isMoveMapAction(from: startPoint, to: endPoint) {
                handleMoveMap(from: startPoint, to: endPoint)
            }
        case .zoom(let startDistance, let currentDistance):
            guard let currentDistance = currentDistance else { break }
            
            let scaleRate = currentDistance / startDistance
            handleZoom(with: scaleRate)
        }
        
        mapState = .none
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapState = .none
        self.layer.setNeedsDisplay()
    }
    
    // MARK: - Handle Methods
    private func calculateDistance(between point1: CGPoint, and point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func isMoveMapAction(from point1: CGPoint, to point2: CGPoint, threshold: CGFloat = 5) -> Bool {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy) > threshold
    }
    
    private func handleMoveMap(from startPoint: CGPoint, to endPoint: CGPoint) {
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        
        var centerXY = worldToPixel(coord: centerCoord)
        centerXY.x -= deltaX
        centerXY.y -= deltaY
        
        centerCoord = pixelToWorld(point: centerXY)
        renderFrame()
        self.layer.setNeedsDisplay()
    }
    
    private func handleZoom(with scaleRate: Double) {
        if scaleRate > 1 {
            zoomIn()
        } else if scaleRate < 1 {
            zoomOut()
        }
    }
}

extension MapView: TileLayerDelegate {
    public func refreshLayer() {
        DispatchQueue.main.async {
            self.layer.setNeedsDisplay()
        }
    }
}
