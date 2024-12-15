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
        var compValue = 0
        
        if list.count > 0{
            if list[0] <= value{
                return 0
            }else if list[list.count-1] >= value{
                return list.count-1
            }else{
                if direction > 0{
                    for i in 1..<list.count{
                        if list[i]<value{
                            return i-1
                        }
                    }
                }else if direction < 0{
                    for i in 1..<list.count{
                        if list[i]<value{
                            return i
                        }
                    }
                }else{
                    for i in 1..<list.count{
                        compValue = compare(d1: list[i], d2: value)
                        
                        if compValue == 0{
                            return i
                        }else if compValue < 0 {
                            if ((list[i-1] - value < (value - list[i]))){
                                return i-1
                            }else{
                                return i
                            }
                        }
                    }
                    return list.count - 1
                }
            }
        }
        return nil
    }
    
    func compare(d1: Double, d2: Double) -> Int{
        if d1 < d2{
            return -1
        }
        if d1 > d2{
            return 1
        }
        
        //let thisBits = doubleToLongBits(value: d1)
        //let anotherBits = doubleToLongBits(value: d2)
        
        return 0
    }
}
