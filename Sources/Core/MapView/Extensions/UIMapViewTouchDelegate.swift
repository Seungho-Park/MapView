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
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouches = event?.allTouches, (1...2).contains(allTouches.count) else { return }
        let touchPoints = allTouches.map { $0.location(in: self) }
        
        if allTouches.count == 1 {
            mapState = .move(startPoint: touchPoints[0], currentPoint: touchPoints[0])
        } else {
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .zoom(startDistance: distance, currentDistance: nil)
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
                mapState = .zoom(startDistance: distance, currentDistance: distance)
            } else {
                let newPoint = touchPoints[0]
                if isMoveMapAction(from: currentPoint, to: newPoint) {
                    mapState = .move(startPoint: startPoint, currentPoint: newPoint)
                    invalidate()
                }
            }
        case .zoom(let startDistance, _):
            guard touchPoints.count == 2 else { break }
            let distance = calculateDistance(between: touchPoints[0], and: touchPoints[1])
            mapState = .zoom(startDistance: startDistance, currentDistance: distance)
            invalidate()
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
        case .zoom(let startDistance, let currentDistance):
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
