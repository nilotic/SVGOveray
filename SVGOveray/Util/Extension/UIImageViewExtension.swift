//
//  UIImageViewExtension.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

extension UIImage {
    
    func resized(size: CGSize) -> UIImage? {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}
