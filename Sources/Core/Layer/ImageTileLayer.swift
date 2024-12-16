//
//  ImageTileLayer.swift
//  MapView
//
//  Created by 박승호 on 12/15/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public class ImageTileLayer: CATiledLayer, TileLayer {
    private let semaphore = DispatchSemaphore(value: 1)
    private var requesters: [any MapRequester] = []
    private var renderingTiles: [(CGImage?, CGRect)] = []
    private var resolution: Double = 0
    
    public let source: any SourceTile
    public var screenExtent: MapExtent!
    public var tileTransform: Transform = .init()
    public var size: CGSize = .zero
    public weak var mapDelegate: TileLayerDelegate?
    
    public init(source: any SourceTile) {
        self.source = source
        super.init()
        
        self.tileSize = .init(width: source.config.tileSize, height: source.config.tileSize)
        self.levelsOfDetail = source.maxZoom
        self.levelsOfDetailBias = 1
        self.drawsAsynchronously = false
        
        for _ in 0..<6 {
            let requester = WMSRequester()
            requester.start(completion: notifyTile(_:))
            requesters.append(requester)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func render(in ctx: CGContext) {
        print("\(#function)")
        
//        ctx.setAllowsAntialiasing(false)
//        ctx.setShouldAntialias(false)
        
        let layerRect = CGRect(
            origin: .init(x: tileTransform.get(4), y: tileTransform.get(5)),
            size: .init(width: size.width * tileTransform.get(0), height: size.height * tileTransform.get(3))
        )
        
        let renderingTiles = renderingTiles
        
        ctx.saveGState()
        ctx.translateBy(x: 0, y: layerRect.height)
        ctx.scaleBy(x: 1, y: -1)
        
        for i in 0..<renderingTiles.count {
            let (tile, rect) = renderingTiles[i]
            if let tile = tile {
                let rect = CGRect(
                    x: layerRect.minX + rect.origin.x,
                    y: layerRect.height - rect.origin.y - rect.height, // Y좌표 반전
                    width: rect.width,
                    height: rect.height
                )
                
                print(rect.minY)
                
                ctx.draw(tile, in: rect.insetBy(dx: -1, dy: -1))
            }
        }
        
        ctx.restoreGState()
    }
    
    public override func draw(in ctx: CGContext) {
        ctx.saveGState()
    }
    
    public func prepareFrame(screenSize: CGSize, center: Coordinate, resolution: Double, angle: Double, extent: MapExtent) {
        guard let level = source.getZForResolution(resolution: resolution, direction: 0),
              let tileRange = source.getTileRangeForExtentAndResolution(extent: extent, resolution: resolution)
        else {
            return
        }
        defer { semaphore.signal() }
        semaphore.wait()
        
        self.resolution = resolution
        renderingTiles.removeAll()
        screenExtent = source.getExtentForTileRange(z: level, tileRange: tileRange)
        
        let renderedTiles = prepare(screenSize: screenSize, center: center, z: level, resolution: resolution, angle: angle, extent: extent, tileRange: tileRange, overSampling: 1.0)
        
        drawTiles(renderedTiles.compactMap { $0 as? ImageTile })
    }
    
    public func manageTilePyramid(_ tiles: [any Tile]) {
        for i in 0..<tiles.count {
            if let tile = tiles[i] as? ImageTile {
                WMSRequesterPool.shared.enqueue(tile)
            }
        }
    }
    
    private func notifyTile(_ tileKeys: [String]) {
        defer { semaphore.signal() }
        semaphore.wait()
        var tiles: [ImageTile] = []
        
        for i in 0..<tileKeys.count {
            let tileKey = tileKeys[i]
            let tile = source.updateTile(forKey: tileKey)
            
            if let tile = tile as? ImageTile,
               source.getResolution(tile.coordinate.z) == resolution
            {
                tiles.append(tile)
            }
        }
        
        drawTiles(tiles)
        mapDelegate?.refreshLayer()
    }
    
    private func drawTiles(_ tiles: [ImageTile], overSampling: Double = 1.0) {
        guard let screenExtent else { return }
        
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: source.config.tileSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        
        for i in 0..<tiles.count {
            let tile = tiles[i]
            guard let image = tile.tileData,
                    tile.tileState == .loaded,
                  let tileExtent = source.getTileCoordExtent(tile.coordinate),
                  let level = source.getZForResolution(resolution: resolution, direction: 0),
                  let resolution = source.getResolution(level)
            else { continue }
            
            let pixelRatio = 1.0
            
            let tileRect = CGRect(
                x: (tileExtent.minLongitude - screenExtent.minLongitude) / resolution * pixelRatio / overSampling,
                y: (screenExtent.maxLatitude - tileExtent.maxLatitude) / resolution * pixelRatio / overSampling,
                width: source.config.tileSize * pixelRatio / overSampling,
                height: source.config.tileSize * pixelRatio / overSampling
            )
            
            if let imageSource = CGImageSourceCreateWithData(image as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) {
                renderingTiles.append((cgImage, tileRect))
            }
        }
    }
}
