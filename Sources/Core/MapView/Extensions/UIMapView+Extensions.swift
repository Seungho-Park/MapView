//
//  UIMapViewTouchDelegate.swift
//  MapView
//
//  Created by 박승호 on 12/21/24.
//  Copyright © 2024 MapView. All rights reserved.
//

#if !os(macOS)
#if canImport(UIKit)
import UIKit
#endif

extension MapView {
    open override func draw(_ layer: CALayer, in ctx: CGContext) {
        self.render(layer, context: ctx)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { self.convert($0.location(in: self), from: nil) }
        
        if allTouches.count == 1 {
            mapState = .move(startPoint: touchPoints[0], currentPoint: touchPoints[0])
        } else {
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .pinchZoom(startDistance: distance, currentDistance: nil)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { self.convert($0.location(in: self), from: nil) }
        
        switch mapState {
        case .none, .wheelZoom:
            mapState = .none
            break
        case .move(let startPoint, let currentPoint):
            if allTouches.count > 1 {
                let touchPoints = [touchPoints[0], touchPoints[1]].map { self.convert($0, from: nil) }
                let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
                mapState = .pinchZoom(startDistance: distance, currentDistance: nil)
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
        case .pinchZoom(let startDistance, _):
            guard touchPoints.count == 2 else { break }
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .pinchZoom(startDistance: startDistance, currentDistance: distance)
            invalidate()
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        switch mapState {
        case .none, .wheelZoom:
            break
        case .move(let startPoint, _):
            guard allTouches.count == 1 else { break }
            let endPoint = touchPoints[0]
            
            if isMoveMapAction(from: startPoint, to: endPoint) {
                handleMoveMap(from: startPoint, to: endPoint)
            }
            
        case .pinchZoom(let startDistance, let currentDistance):
            guard let currentDistance = currentDistance else { break }
            
            let scaleRate = currentDistance / startDistance
            handleZoom(with: scaleRate)
        }
        
        mapState = .none
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapState = .none
        invalidate()
    }
}
#endif
