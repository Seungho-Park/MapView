//
//  MapView.swift
//  MapView
//
//  Created by 박승호 on 12/15/24.
//
import Foundation
import UIKit

private enum MapState {
    case none
    case move(CGPoint?, CGPoint?)
    case zoom(Double?, Double?)
}

open class MapView: UIView {
    private var canvasLayer: CALayer = .init()
    private var mapLayer: (any TileLayer)!
    private var mapState: MapState = .none
    private let lonlatToPixelTransform = Transform()
    private let pixelToLonlatTransform = Transform()
    
    private let zoomFactor = 2.0
    private var resolution: Double = .zero
    private var centerCoord: Coordinate = .init(latitude: 4263282, longitude: 14287820)
    private var zoom: Int = 7
    private var angle: Double = 0
    private var isAvailableRotate: Bool = false
    
    public convenience init(config: MapConfigurable) {
        self.init(frame: .zero)
        
        if let config = config as? WMSConfig {
            mapLayer = ImageTileLayer(source: TileWMS(config: config))
        }
        
        mapLayer.mapDelegate = self
        self.zoom = config.initialZoom
        
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
        canvasLayer.isOpaque = false
        mapLayer.isOpaque = false
        
        canvasLayer.addSublayer(mapLayer)
        self.layer.addSublayer(canvasLayer)
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        canvasLayer.frame = rect
        apply(screenSize: rect.size)
        renderFrame(rect: rect)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        var viewRect: CGRect = canvasLayer.frame
        
        switch mapState {
        case .move(let downPoint, let movePoint):
            let moveX = movePoint!.x - downPoint!.x
            let moveY = movePoint!.y - downPoint!.y
            viewRect = CGRect(x: moveX, y: moveY, width: canvasLayer.frame.width, height: canvasLayer.frame.height)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            canvasLayer.frame = viewRect
            CATransaction.commit()
        case .zoom(let startDistance, let moveDistance):
            guard let moveDistance = moveDistance,
                  let startDistance = startDistance
            else {
                break
            }
            
            var scaleRate = moveDistance / startDistance
            scaleRate = scaleRate < 0.5 ? 0.5 : scaleRate > 2.0 ? 2.0 : scaleRate
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            canvasLayer.setAffineTransform(.init(scaleX: scaleRate, y: scaleRate))
            CATransaction.commit()
        case .none:
            mapLayer.render()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            canvasLayer.setAffineTransform(.identity)
            canvasLayer.frame = self.bounds
            CATransaction.commit()
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
    
    private func apply(screenSize: CGSize) {
        let extent = mapLayer.source.extent
        let size = max(extent.width, extent.height)
        let maxResolution = size / mapLayer.source.config.tileSize / pow(2, 0)
        
        resolution = createSnapToPower(delta:Int(zoom - mapLayer.source.config.minZoom), resolution: maxResolution / pow(zoomFactor, Double(mapLayer.source.config.minZoom)), direction: 0)
        
        lonlatToPixelTransform.composite(screenSize.width / 2, screenSize.height / 2, -centerCoord.longitude, -centerCoord.latitude, 1 / resolution, -1 / resolution, angle)
        pixelToLonlatTransform.inverse(transform: lonlatToPixelTransform)
    }
    
    private func renderFrame(rect: CGRect) {
        mapLayer.prepareFrame(screenSize: rect.size, center: centerCoord, resolution: resolution, angle: angle, extent: getScreenExtent(size: rect.size))
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

public extension MapView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let count = event?.allTouches?.count, (count > 0 && count < 3),
              let touches = event?.allTouches?.map({ $0.location(in: self) })
        else { return }
        
        if count == 1 {
            mapState = .move(touches.first!, touches.first!)
        } else {
            let x = touches[0].x - touches[1].x
            let y = touches[0].y - touches[1].y
            
            mapState = .zoom(sqrt(x*x + y*y), nil)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let count = event?.allTouches?.count, (count > 0 && count < 3),
              let touches = event?.allTouches?.map({ $0.location(in: self) })
        else { return }
        
        switch mapState {
        case .none: break
        case .move(let downPoint, let movePoint):
            if count > 1 {
                let x = touches[0].x - touches[1].x
                let y = touches[0].y - touches[1].y
                mapState = .zoom(sqrt(x*x + y*y), sqrt(x*x + y*y))
                break
            }
            let newMovePoint = touches.first!
            if (round(newMovePoint.x) != round(movePoint!.x)) || (round(newMovePoint.y) != round(movePoint!.y)) {
                mapState = .move(downPoint, newMovePoint)
                
                let xLen = newMovePoint.x - downPoint!.x
                let yLen = newMovePoint.y - downPoint!.y
                
                if sqrt(pow(xLen, 2) + pow(yLen, 2)) > 5 {
                    self.setNeedsLayout()
                }
            }
        case .zoom(let startDistance, _):
            if count < 2 { break }
            let x = touches[0].x - touches[1].x
            let y = touches[0].y - touches[1].y
            
            mapState = .zoom(startDistance, sqrt(x*x + y*y))
            setNeedsLayout()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let count = event?.allTouches?.count, (count > 0 && count < 3),
              let touches = event?.allTouches?.map({ $0.location(in: self) })
        else { return }
        
        switch mapState {
        case .none: break
        case .move(let downPoint, _):
            if count > 1 { break }
            let touchUp = touches.first!
            
            let xLen = touchUp.x - downPoint!.x
            let yLen = touchUp.y - downPoint!.y
            
            if sqrt(pow(xLen, 2) + pow(yLen, 2)) < 5{
                break
            }
            
            var centerXY = worldToPixel(coord: centerCoord)
            centerXY.x -= xLen
            centerXY.y -= yLen
            
            self.centerCoord = pixelToWorld(point: centerXY)
            renderFrame(rect: self.frame)
            setNeedsLayout()
        case .zoom(let startDistance, let moveDistance):
            let scaleRate: Double
            if touches.count < 2 {
                guard let start = startDistance, let move = moveDistance else {
                    mapState = .none
                    setNeedsLayout()
                    return
                }
                
                scaleRate = move / start
            } else {
                let x = touches[0].x - touches[1].x
                let y = touches[0].y - touches[1].y
                
                scaleRate = sqrt(x*x + y*y) / startDistance!
            }
        }
        
        mapState = .none
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapState = .none
        setNeedsLayout()
    }
}

extension MapView: TileLayerDelegate {
    public func refreshLayer() {
        DispatchQueue.main.async {
            self.setNeedsLayout()
        }
    }
}
