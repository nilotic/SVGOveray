//
//  ResourceCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

final class ResourceCell: UICollectionViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet var imageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "ResourceCell"
    
    
    // MARK: Private
    private var imageURL: ImageURL?   = nil
    
    
    
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
        imageView.image = nil
        ImageDataManager.shared.cancel(url: imageURL)
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func update(data: URL) {
        imageURL = ImageURL(url: data, hash: hash)
        activityIndicatorView.startAnimating()
        
        ImageDataManager.shared.download(url: imageURL) { [weak self] (url, image) in
            DispatchQueue.main.async {
                guard self?.imageURL == url else { return }
                self?.activityIndicatorView.stopAnimating()
                self?.imageView.image = image
            }
        }
    }
}
