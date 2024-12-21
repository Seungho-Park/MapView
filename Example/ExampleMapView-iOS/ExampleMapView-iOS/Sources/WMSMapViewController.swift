//
//  WMSMapViewController.swift
//  ExampleMapView-iOS
//
//  Created by 박승호 on 12/21/24.
//

import UIKit
import MapView

class WMSMapViewController: UIViewController {
    let mapView: MapView = {
        let view = MapView(map: TileWMS(config: .init(baseUrl: "http://ows.mundialis.de/services/service", requestType: "GetMap", parameters: ["LAYERS":"OSM-WMS", "STYLES":""])))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationItem.title = "WMS"
        
        self.view.addSubview(mapView)
        NSLayoutConstraint.activate([
            .init(item: mapView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            .init(item: mapView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            .init(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: mapView, attribute: .trailing, multiplier: 1, constant: 0),
            .init(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
}
