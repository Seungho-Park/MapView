//
//  Comparable+Extensions.swift
//  MapView
//
//  Created by 박승호 on 11/23/24.
//
import Foundation

public extension Comparable {
    func clamp(_ min: Self, _ max: Self)-> Self {
        return Swift.min(Swift.max(self, min), max)
    }
}
