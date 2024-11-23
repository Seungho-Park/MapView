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
            }
            
            if isDescending {
                if list[mid] > value {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            } else {
                if list[mid] < value {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
        }
        
        switch direction {
        case 1:
            if isDescending {
                return high >= 0 ? high : nil
            } else {
                return low < list.count ? low : nil
            }
        case -1:
            if isDescending {
                return low < list.count ? low : nil
            } else {
                return high >= 0 ? high : nil
            }
        default:
            if high < 0 { return low }
            if low >= list.count { return high }
            
            let diffLow = abs(list[low] - value)
            let diffHigh = abs(list[high] - value)
            return diffLow < diffHigh ? low : high
        }
    }
}
