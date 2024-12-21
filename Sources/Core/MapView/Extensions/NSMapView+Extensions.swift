//
//  NSMapViewTouchDelegate.swift
//  MapView
//
//  Created by 박승호 on 12/21/24.
//  Copyright © 2024 MapView. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif

#if os(macOS)
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
        case .none, .zoom:
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
        case .none, .zoom:
            break
        case .move(let startPoint, _):
            let endPoint = event.locationInWindow
            
            if isMoveMapAction(from: startPoint, to: endPoint) {
                handleMoveMap(from: startPoint, to: endPoint)
            }
        }
        
        mapState = .none
    }
    
    open override func scrollWheel(with event: NSEvent) {
        switch event.phase {
        case .began:
            mapState = .zoom(startDistance: event.deltaY, currentDistance: event.scrollingDeltaY)
        default:
            if case .zoom = mapState {
                handleZoom(with: event.scrollingDeltaY)
                mapState = .none
            }
        }
    }
    
    open override func mouseExited(with event: NSEvent) {
        
    }
}
#endif
