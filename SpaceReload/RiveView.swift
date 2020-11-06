//
//  RiveView.swift
//  SpaceReload
//
//  Created by Alex Gibson on 20/10/2020.
//

import UIKit
import RiveRuntime

class RiveView: UIView {

    var artboard: RiveArtboard?;
    
    func updateArtboard(_ artboard: RiveArtboard) {
        self.artboard = artboard;
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect, withContentRect: artboard.bounds(), with: .Center, with: .Cover)
        artboard.draw(renderer)
    }
}
