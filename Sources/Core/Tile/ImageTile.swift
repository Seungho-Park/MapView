//
//  ImageTile.swift
//  MapView
//
//  Created by 박승호 on 11/19/24.
//
import Foundation

public final class ImageTile: Tile {
    
    public var key: String
    public var coordinate: TileCoordinate
    public var url: String
    public var tileState: TileState
    public var tileData: Data?
    
    public init(key: String, coordinate: TileCoordinate, url: String, tileState: TileState = .idle, tileData: Data? = nil) {
        self.key = key
        self.coordinate = coordinate
        self.url = url
        self.tileState = tileState
        self.tileData = tileData
    }
    
    public func load(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: url)
        else {
            tileState = .error
            tileData = nil
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                self.tileState = .error
                self.tileData = nil
                completion(false)
            }
            
            if let data = data {
                self.tileState = data.isEmpty ? .empty : .loaded
            } else {
                self.tileState = .empty
            }
            
            self.tileData = data
            completion(true)
        }.resume()
    }
    
    public func load() async -> Bool {
        guard let url = URL(string: url)
        else {
            tileState = .error
            tileData = nil
            return false
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            tileState = data.isEmpty ? .empty : .loaded
            tileData = data
            return true
        } catch {
            tileState = .error
            tileData = nil
            return false
        }
    }
}
