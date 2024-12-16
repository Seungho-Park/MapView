//
//  TileLayer.swift
//  MapView
//
//  Created by 박승호 on 11/22/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public protocol TileLayerDelegate: AnyObject {
    func refreshLayer()
}

public protocol TileLayer: CALayer {
    typealias CompletionHandler = (Result<CGImage?, Error>)-> Void
    
    var source: any SourceTile { get }
    var mapDelegate: TileLayerDelegate? { get set }
    var screenExtent: MapExtent! { get set }
    var tileTransform: Transform { get }
    var size: CGSize { get set }
    
    func manageTilePyramid(_ tiles: [any Tile])
    func prepareFrame(screenSize: CGSize, center: Coordinate, resolution: Double, angle: Double, extent: MapExtent)
}

public extension TileLayer {    
    internal func prepare(screenSize: CGSize, center: Coordinate, z: Int, resolution: Double, angle: Double, extent: MapExtent, tileRange: TileRange, overSampling: Double)-> [any Tile] {
        var renderedTiles: [any Tile] = []
        
        for x in tileRange.minX...tileRange.maxX {
            for y in tileRange.minY...tileRange.maxY {
                if let tile = source.getTile(z, x, y, 1) {
                    if tile.tileState == .loaded {
                        renderedTiles.append(tile)
                    }
                }
            }
        }
        
        let pixelRatio: Double = 1.0
        let scale: Double = 1.0
        let width = round(Double(tileRange.width) * Double(source.config.tileSize) / overSampling)
        let height = round(Double(tileRange.height) * Double(source.config.tileSize) / overSampling)
        
        if size.width != width || size.height != height {
            size = .init(width: width, height: height)
        }
        
        tileTransform.composite(pixelRatio * screenSize.width / 2.0, pixelRatio * screenSize.height / 2.0, (screenExtent.minLongitude - center.longitude) / resolution * pixelRatio, (center.latitude - screenExtent.maxLatitude) / resolution * pixelRatio, scale, scale, angle)
        
        
        manageTilePyramid(getTilePyramid(extent: extent, z: z, preLoad: 0, pixelRatio: 1.0))
        
        return renderedTiles
    }
    
    private func getTilePyramid(extent: MapExtent, z: Int, preLoad: Int, pixelRatio: Double)-> [any Tile] {
        var tiles: [(Double, any Tile)] = []
        
        for level in stride(from: z, through: source.minZoom, by: -1) {
            guard let tileRange = source.getTileRangeForExtentAndZ(extent: extent, z: z),
                  let tileResolution = source.getResolution(z)
            else {
                continue
            }
            
            for x in tileRange.minX...tileRange.maxX {
                for y in tileRange.minY...tileRange.maxY {
                    if z - level <= preLoad {
                        if var tile = source.getTile(level, x, y, pixelRatio),
                           let center = source.getCenterForTileCoordinate(tileCoord: tile.coordinate),
                           tile.tileState == .idle {
                            tile.tileState = .loading
                            
                            tiles.append((getTilePriority(tileCoord: tile.coordinate, center: center, tileResolution: tileResolution), tile))
                        }
                    }
                }
            }
        }
        
        return tiles.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
    
    private func getTilePriority(tileCoord: TileCoordinate, center: Coordinate, tileResolution: Double)-> Double {
        let deltaX = center.longitude - Double(tileCoord.x)
        let deltaY = center.latitude - Double(tileCoord.y)
        
        return 65536 * log(tileResolution) + sqrt(pow(deltaX, 2) + pow(deltaY, 2)) / tileResolution
    }
}
