//
//  MapRequester.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

public protocol ServiceRequester {
    typealias CompletionHandler = ([String])-> Void
    var requesterPool: any ServiceRequesterPool { get }
    var isActive: Bool { get set }
    
    func start(completion: @escaping CompletionHandler)
}
