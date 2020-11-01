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
    
    func cropped(frame: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        let rect = CGRect(x: frame.origin.x * scale, y: frame.origin.y * scale, width: frame.width * scale, height: frame.height * scale)
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
}
