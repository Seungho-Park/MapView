//
//  ViewController.swift
//  ExampleMapView-iOS
//
//  Created by 박승호 on 12/21/24.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var btnWMSMapScene: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapWMSButton), for: .touchUpInside)
        btn.setTitle("WMS", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    private lazy var btnTileMapScene: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapTileMapButton), for: .touchUpInside)
        btn.setTitle("WMTS/TMS", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationItem.title = "ExampleMapView - iOS"
        
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.addArrangedSubview(btnWMSMapScene)
        stack.addArrangedSubview(btnTileMapScene)
        
        self.view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            .init(item: stack, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0),
            .init(item: stack, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 20),
            .init(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: stack, attribute: .trailing, multiplier: 1, constant: 20)
        ])
    }
    
    @objc
    func didTapWMSButton() {
        self.navigationController?.pushViewController(WMSMapViewController(), animated: true)
    }
    
    @objc
    func didTapTileMapButton() {
        self.navigationController?.pushViewController(TileMapViewController(), animated: true)
    }
}

