//
//  Transform.swift
//  MapView
//
//  Created by 박승호 on 12/15/24.
//
import Foundation

public class Transform {
    private var values: [Double] = .init(repeating: 0, count: 6)
    
    var determinant: Double {
        return values[0] * values[3] - values[1] * values[2]
    }
    
    func composite(_ dx1: Double, _ dy1: Double, _ dx2: Double, _ dy2: Double, _ sx: Double, _ sy: Double, _ angle: Double) {
        let sinv = sin(angle.toRadian)
        let cosv = cos(angle.toRadian)
        
        values[0] = sx * cosv
        values[1] = sy * sinv
        values[2] = -sx * sinv
        values[3] = sy * cosv
        values[4] = dx2 * sx * cosv - dy2 * sx * sinv + dx1
        values[5] = dx2 * sy * sinv + dy2 * sy * cosv + dy1
    }
    
    func inverse(transform: Transform) {
        values[0] = transform.get(3) / transform.determinant
        values[1] = -transform.get(1) / transform.determinant
        values[2] = -transform.get(2) / transform.determinant
        values[3] = transform.get(0) / transform.determinant
        values[4] = (transform.get(2) * transform.get(5) - transform.get(3) * transform.get(4)) / transform.determinant
        values[5] = -(transform.get(0) * transform.get(5) - transform.get(1) * transform.get(4)) / transform.determinant
    }
    
    func get(_ idx: Int)-> Double {
        return values[idx]
    }
}
