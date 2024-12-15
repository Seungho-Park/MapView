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
    private var mapLayer: CALayer = .init()
    private var mapState: MapState = .none
    
    public convenience init(config: MapConfigurable) {
        self.init(frame: .zero)
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
        mapLayer.frame = canvasLayer.frame
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
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
            
            print(sqrt(x*x + y*y) / startDistance!)
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
