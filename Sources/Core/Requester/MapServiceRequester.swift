//
//  WMSRequester.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//
import Foundation

internal final class MapServiceRequester: ServiceRequester {
    private let dispatchQueue: DispatchQueue = .init(label: "net.devswift.webview.WMSRequester", qos: .utility, attributes: .concurrent)
    public var requesterPool: any ServiceRequesterPool
    public var isActive: Bool
    
    public init(requesterPool: any ServiceRequesterPool = MapServiceRequesterPool.shared, isActive: Bool = true) {
        self.requesterPool = requesterPool
        self.isActive = isActive
    }
    
    public func start(completion: @escaping CompletionHandler) {
        dispatchQueue.async { [weak self] in
            Thread.current.name = "\(Self.self)"
            
            var tileKeyList: [String] = []
            while self?.isActive == true {
                guard let tile = self?.requesterPool.dequeue()
                else {
                    if !tileKeyList.isEmpty {
                        completion(tileKeyList)
                        tileKeyList.removeAll()
                    }
                    
                    Thread.sleep(forTimeInterval: 0.1)
                    continue
                }
                
                if tile.load() {
                    tileKeyList.append(tile.key)
                }
            }
        }
    }
}
