//
//  NSMapViewTouchDelegate.swift
//  MapView
//
//  Created by 박승호 on 12/21/24.
//  Copyright © 2024 MapView. All rights reserved.
//

#if os(macOS)
#if canImport(AppKit)
import AppKit
#endif

extension MapView: CALayerDelegate {
    open override var isFlipped: Bool {
        return true
    }
    
    open override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.needsDisplayOnBoundsChange = true
        layer.delegate = self
        return layer
    }
    
    public func draw(_ layer: CALayer, in ctx: CGContext) {
        render(layer, context: ctx)
    }
    
    open override func mouseDown(with event: NSEvent) {
        mapState = .move(startPoint: event.locationInWindow, currentPoint: event.locationInWindow)
    }
    
    open override func mouseDragged(with event: NSEvent) {
        switch mapState {
        case .none, .pinchZoom, .wheelZoom:
            break
        case .move(let prevPoint, let currentPoint):
            let newPoint = event.locationInWindow
            if isMoveMapAction(from: currentPoint, to: newPoint) {
                let dx = newPoint.x - prevPoint.x
                let dy = prevPoint.y - newPoint.y
                
                var centerXY = worldToPixel(coord: centerCoord)
                centerXY.x -= dx
                centerXY.y -= dy
                centerCoord = pixelToWorld(point: centerXY)
                
                mapState = .move(startPoint: newPoint, currentPoint: newPoint)
                
                renderFrame()
                invalidate()
            }
        }
    }
    
    open override func mouseUp(with event: NSEvent) {
        switch mapState {
        case .none, .pinchZoom, .wheelZoom:
            break
        case .move(let startPoint, _):
            let endPoint = event.locationInWindow
            
            if isMoveMapAction(from: startPoint, to: endPoint) {
                handleMoveMap(from: startPoint, to: endPoint)
            }
        }
        
        mapState = .none
    }
    
    open override func magnify(with event: NSEvent) {
        switch self.mapState {
        case .pinchZoom(let startDistance, let currentDistance):
            if event.phase == .ended {
                let scaleRate = currentDistance! / startDistance
                handleZoom(with: scaleRate)
                mapState = .none
            } else {
                mapState = .pinchZoom(startDistance: startDistance, currentDistance: (currentDistance ?? 1.0) + event.magnification)
            }
        default :
            mapState = .pinchZoom(startDistance: 1.0 + event.magnification, currentDistance: 1.0 + event.magnification)
        }
        
        invalidate()
    }
    
    open override func scrollWheel(with event: NSEvent) {
        switch event.phase {
        case .began:
            let localPt = self.convert(event.locationInWindow, from: nil)
            let worldCoord = pixelToWorld(point: localPt)
            mapState = .wheelZoom(controlPoint: worldCoord)
            
        case .changed:
            if case .wheelZoom(let coord) = mapState {
                if event.deltaY > 0 {
                    zoomIn()
                } else if event.deltaY < 0 {
                    zoomOut()
                }
                
                apply()
                renderFrame()
                
                let controlPoint = worldToPixel(coord: coord)
                
                let localPt = self.convert(event.locationInWindow, from: nil)
                
                let dx = localPt.x - controlPoint.x
                let dy = localPt.y - controlPoint.y
                
                var centerXY = worldToPixel(coord: centerCoord)
                centerXY.x -= dx
                centerXY.y -= dy
                centerCoord = pixelToWorld(point: centerXY)
                
                mapState = .wheelZoom(controlPoint: coord)
                apply()
                renderFrame()
                invalidate()
            }
            
        default:
            mapState = .none
        }
    }
    
    open override func mouseExited(with event: NSEvent) {
        
    }
}
#endif
