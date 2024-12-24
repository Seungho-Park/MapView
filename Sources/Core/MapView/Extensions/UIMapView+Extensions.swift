//
//  UIMapViewTouchDelegate.swift
//  MapView
//
//  Created by 박승호 on 12/21/24.
//  Copyright © 2024 MapView. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif

#if !os(macOS)
extension MapView {
    open override func draw(_ layer: CALayer, in ctx: CGContext) {
        self.render(layer, context: ctx)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        if allTouches.count == 1 {
            mapState = .move(startPoint: touchPoints[0], currentPoint: touchPoints[0])
        } else {
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .pinchZoom(center: .init(x: (touchPoints[0].x + touchPoints[1].x) / 2, y: (touchPoints[0].y + touchPoints[1].y) / 2), startZoom: zoom, distance: distance, scale: 1)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        switch mapState {
        case .none:
            break
        case .move(let startPoint, let currentPoint):
            if allTouches.count > 1 {
                let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
                mapState = .pinchZoom(center: .init(x: (touchPoints[0].x + touchPoints[1].x) / 2, y: (touchPoints[0].y + touchPoints[1].y) / 2), startZoom: zoom, distance: distance, scale: 1)
            } else {
                let newPoint = touchPoints[0]
                if isMoveMapAction(from: currentPoint, to: newPoint) {
                    let dx = newPoint.x - startPoint.x
                    let dy = newPoint.y - startPoint.y

                    var centerXY = worldToPixel(coord: centerCoord)
                    centerXY.x -= dx
                    centerXY.y -= dy
                    centerCoord = pixelToWorld(point: centerXY)

                    mapState = .move(startPoint: newPoint, currentPoint: newPoint)

                    renderFrame()
                    invalidate()
                }
            }
        case .pinchZoom(let center, let startZoom, let distance, let scale):
            guard touchPoints.count == 2 else { break }
            
            let newPoint: CGPoint = .init(x: (touchPoints[0].x + touchPoints[1].x) / 2, y: (touchPoints[0].y + touchPoints[1].y) / 2)
            
            let dx = newPoint.x - center.x
            let dy = newPoint.y - center.y
            
            var centerXY = worldToPixel(coord: centerCoord)
            centerXY.x -= dx
            centerXY.y -= dy
            centerCoord = pixelToWorld(point: centerXY)
            
            let newDistance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .pinchZoom(center: newPoint, startZoom: startZoom, distance: distance, scale: newDistance / distance)
            handleZoom(zoom: startZoom, scale: newDistance / distance)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        case .pinchZoom(_, let startZoom, _, let scale):
            handleZoom(zoom: startZoom, scale: scale)
//            guard let currentDistance = currentDistance else { break }
//            
//            let scaleRate = currentDistance / startDistance
        }
        
        mapState = .none
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapState = .none
        invalidate()
    }
}
#endif
