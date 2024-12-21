//
//  TileMapViewController.swift
//  ExampleMapView-iOS
//
//  Created by 박승호 on 12/21/24.
//

import UIKit
import MapView

enum OSMTileLayerType: TileMapServiceLayer {
    var layer: String { switch self { case .empty: return "" } }
    var minZoom: Int { return 6 }
    var maxZoom: Int { return 19 }
    var tileType: String { return "png" }
    
    case empty
}

class TileMapViewController: UIViewController {
    let mapView: MapView = {
        let view = MapView(map: TileTMS(config: .init(type: .tms, baseUrl: "https://tiles.osm.kr/hot", initialZoom: 6, layer: OSMTileLayerType.empty)))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationItem.title = "WMTS/TMS"
        
        self.view.addSubview(mapView)
        NSLayoutConstraint.activate([
            .init(item: mapView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            .init(item: mapView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            .init(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: mapView, attribute: .trailing, multiplier: 1, constant: 0),
            .init(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
}
