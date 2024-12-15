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

public class ImageTileLayer: CALayer, TileLayer {
    private var requesters: [any MapRequester] = []
    private var renderingTiles: [(CGImage, CGRect)] = []
    private var resolution: Double = 0
    
    public let source: any SourceTile
    public var screenExtent: MapExtent!
    public var tileTransform: Transform = .init()
    public var size: CGSize = .zero
    public weak var mapDelegate: TileLayerDelegate?
    
    public init(source: any SourceTile) {
        self.source = source
        super.init()
        for _ in 0..<6 {
            let requester = WMSRequester()
            requester.start(completion: notifyTile(_:))
            requesters.append(requester)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func render() {
        let layerRect = CGRect(
            origin: .init(x: tileTransform.get(4), y: tileTransform.get(5)),
            size: .init(width: size.width * tileTransform.get(0), height: size.height * tileTransform.get(3))
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 0.0
        let renderer = UIGraphicsImageRenderer(size: layerRect.size, format: format)
        let renderedImage = renderer.image { [weak self] _ in
            guard let self else { return }
            for i in 0..<renderingTiles.count {
                autoreleasepool {
                    let (tile, rect) = self.renderingTiles[i]
                    UIImage(cgImage: tile).draw(in: rect)
                }
            }
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.frame = layerRect
        self.contents = renderedImage.cgImage
        CATransaction.commit()
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
        for i in 0..<tiles.count {
            if let tile = tiles[i] as? ImageTile {
                WMSRequesterPool.shared.enqueue(tile)
            }
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
                renderingTiles.append((cgImage, tileRect))
            }
        }
    }
}
