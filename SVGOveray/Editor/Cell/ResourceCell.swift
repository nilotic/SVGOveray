//
//  ResourceCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import SwiftSVG

final class ResourceCell: UICollectionViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "ResourceCell"
    
    
    // MARK: Private
    private var imageURL: ImageURL?   = nil
    private weak var svgView: UIView? = nil
    
    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10.0
        layer.borderWidth  = 1.0
        layer.borderColor  = UIColor(named: "title")?.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset the imageView
        svgView?.removeFromSuperview()
        ImageDataManager.shared.cancel(url: imageURL)
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func update(data: URL) {
        imageURL = ImageURL(url: data, hash: hash)
        activityIndicatorView.startAnimating()
        
        ImageDataManager.shared.download(url: imageURL) { [weak self] (url, data) in
            DispatchQueue.main.async {
                guard self?.imageURL == url else { return }
                self?.activityIndicatorView.stopAnimating()
                
                guard let data = data, let bounds = self?.bounds else { return }
                let view = UIView(svgData: data) { layer in
                    layer.resizeToFit(CGRect(x: 0, y: 0, width: bounds.size.width - 20.0, height: bounds.size.height - 20.0))
                }
    
                view.frame.origin = CGPoint(x: 10.0, y: 10.0)
                self?.svgView = view
                self?.addSubview(view)
            }
        }
    }
}
