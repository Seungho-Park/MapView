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
extension MapView {
    open override var isFlipped: Bool {
        return true
    }
    
    open override func mouseDown(with event: NSEvent) {
        mapState = .move(startPoint: event.locationInWindow, currentPoint: event.locationInWindow)
    }
    
    open override func mouseDragged(with event: NSEvent) {
        switch mapState {
        case .none, .zoom:
            break
        case .move(let startPoint, let currentPoint):
            let newPoint = event.locationInWindow
            if isMoveMapAction(from: currentPoint, to: newPoint) {
                mapState = .move(startPoint: startPoint, currentPoint: newPoint)
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
    
    open override func mouseExited(with event: NSEvent) {
        
    }
}
#endif
