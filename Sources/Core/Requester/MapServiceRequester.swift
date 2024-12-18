//
//  WMSRequester.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//
import Foundation

internal final class MapServiceRequester: ServiceRequester {
    private var task: Task<Void, Never>?
    public var requesterPool: any ServiceRequesterPool
    public var isActive: Bool
    
    public init(requesterPool: any ServiceRequesterPool = MapServiceRequesterPool.shared, isActive: Bool = true) {
        self.requesterPool = requesterPool
        self.isActive = isActive
    }
    
    public func start(completion: @escaping CompletionHandler) {
        task = Task {
            var tileKeyList: [String] = []
            while self.isActive == true {
                if let tile = self.requesterPool.dequeue() {
                    let isLoaded = await tile.load()
                    if isLoaded {
                        tileKeyList.append(tile.key)
                    }
                } else {
                    if !tileKeyList.isEmpty {
                        completion(tileKeyList)
                        tileKeyList.removeAll()
                    }
                    
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
    }
    
    func stop() {
        isActive = false
        task?.cancel()
        task = nil
    }
}
