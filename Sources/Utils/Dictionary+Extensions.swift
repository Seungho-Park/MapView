//
//  Dictionary+Extensions.swift
//  WMSView
//
//  Created by 박승호 on 11/18/24.
//
import Foundation

internal extension Dictionary {
    var urlQueryParameters: String {
        return self.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}
