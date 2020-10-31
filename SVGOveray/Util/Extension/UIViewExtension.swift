//
//  UIViewExtension.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

extension UIView {
    
    var renderedImage: UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in layer.render(in: rendererContext.cgContext) }
    }
}
