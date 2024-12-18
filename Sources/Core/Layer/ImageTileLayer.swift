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
    private let dispatchQueue = DispatchQueue(label: "ImageTileLayer", qos: .userInteractive)
    private var _renderingTiles: [(CGImage?, CGRect)] = []
    private var renderingTiles: [(CGImage?, CGRect)] {
        get { dispatchQueue.sync { _renderingTiles } }
        set { dispatchQueue.sync { _renderingTiles = newValue } }
    }
    private var requesters: [any ServiceRequester] = []
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
        self.drawsAsynchronously = true
        self.shouldRasterize = true
        
        for _ in 0..<6 {
            let requester = MapServiceRequester()
            requester.start(completion: notifyTile(_:))
            requesters.append(requester)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func render(in ctx: CGContext) {
        print("\(#function)")
        
        let layerRect = CGRect(
            origin: .init(x: tileTransform.get(4), y: tileTransform.get(5)),
            size: .init(width: size.width * tileTransform.get(0), height: size.height * tileTransform.get(3))
        )
        
        let renderingTiles = renderingTiles
        
        ctx.saveGState()
        ctx.translateBy(x: layerRect.minX, y: layerRect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        
        //Empty Background Color
        ctx.setFillColor(UIColor(red: 52/255, green: 58/255, blue: 64/255, alpha: 1).cgColor)
        ctx.fill([ctx.boundingBoxOfClipPath])
        
        for i in 0..<renderingTiles.count {
            let (tile, rect) = renderingTiles[i]
            if let tile = tile {
                let rect = CGRect(
                    x: rect.origin.x,
                    y: layerRect.height - rect.origin.y - rect.height,
                    width: rect.width,
                    height: rect.height
                )
                
                ctx.draw(tile, in: rect)
            }
        }
        
        ctx.restoreGState()
    }
    
    public func prepareFrame(screenSize: CGSize, center: Coordinate, resolution: Double, angle: Double, extent: MapExtent) {
        guard let level = source.getZForResolution(resolution: resolution, direction: 0),
              let tileRange = source.getTileRangeForExtentAndResolution(extent: extent, resolution: resolution)
        else {
            return
        }
        
        self.resolution = resolution
        renderingTiles.removeAll()
        screenExtent = source.getExtentForTileRange(z: level, tileRange: tileRange)
        
        let renderedTiles = prepare(screenSize: screenSize, center: center, z: level, resolution: resolution, angle: angle, extent: extent, tileRange: tileRange, overSampling: 1.0)
        
        drawTiles(renderedTiles.compactMap { $0 as? ImageTile })
    }
    
    public func manageTilePyramid(_ tiles: [any Tile]) {
        tiles.compactMap { $0 as? ImageTile }.forEach { tile in
            MapServiceRequesterPool.shared.enqueue(tile)
        }
    }
    
    private func notifyTile(_ tileKeys: [String]) {
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
                self.renderingTiles.append((cgImage, tileRect))
            }
        }
    }
}
