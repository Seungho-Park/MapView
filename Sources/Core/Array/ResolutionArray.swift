//
//  ResolutionArray.swift
//  MapView
//
//  Created by 박승호 on 11/23/24.
//

import Foundation

public final class ResolutionArray {
    private var list: [Double] = []
    
    var count: Int {
        return list.count
    }
    
    func get(_ index: Int)-> Double? {
        if index >= 0 && index < count {
            return list[index]
        }
        
        return nil
    }
    
    func sort(isDescending: Bool = false) {
        if isDescending {
            list.sort(by: <)
        } else {
            list.sort(by: >)
        }
    }
    
    func add(_ value: Double) {
        list.append(value)
    }
    
    func findNearest(value: Double, direction: Int, isDescending: Bool = false) -> Int? {
        guard !list.isEmpty else { return nil }
        
        var low = 0
        var high = list.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            
            if list[mid] == value {
                return mid
            } else if list[mid] < value {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        
        if direction > 0 {
            return high >= 0 ? high : nil
        } else if direction < 0 {
            return low < list.count ? low : nil
        } else {
            let lowerIndex = high >= 0 ? high : nil
            let upperIndex = low < list.count ? low : nil
            
            if let lower = lowerIndex, let upper = upperIndex {
                return abs(list[lower] - value) <= abs(list[upper] - value) ? lower : upper
            }
            return lowerIndex ?? upperIndex
        }
    }
}
