//
//  Double+Extensions.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

public extension Double {
    var toDegree: Double {
        return self * 180 / .pi
    }
    
    var toRadian: Double {
        return self * .pi / 180
    }
}
