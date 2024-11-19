//
//  Double+ExtensionTests.swift
//  MapView
//
//  Created by 박승호 on 11/18/24.
//

import XCTest
@testable import MapView_iOS

final class DoubleExtensionsTests: XCTestCase {
    func testWhenRadianToDeg_ShouldReturnCorrectValue() {
        let radian: Double = 0.1
        
        XCTAssertEqual(round(radian.toDegree * 100000) / 100000, 5.72958)
    }
    
    func testWhenDegreeToRadian_ShouldReturnCorrectValue() {
        let degree: Double = 57.2958
        
        XCTAssertEqual(round(degree.toRadian), 1)
    }
}
