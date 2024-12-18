//
//  Bundle+Extensions.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//

import Foundation

public extension Bundle {
    static var MapView: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(identifier: "net.devswift.MapView")!
        #endif
    }
}
