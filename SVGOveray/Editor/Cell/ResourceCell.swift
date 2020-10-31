//
//  ResourceCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

final class ResourceCell: UICollectionViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet private var resourceImageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Private
    private var imageURL: ImageURL? = nil
    
    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10.0
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(named: "title")?.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resourceImageView.image = nil
        ImageDataManager.shared.download(url: imageURL)
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func update(data: URL) {
        // Image
        imageURL = ImageURL(url: data, hash: hash)
        activityIndicatorView.startAnimating()
        
        ImageDataManager.shared.download(url: imageURL) { [weak self] (url, image) in
            DispatchQueue.main.async {
                guard self?.imageURL == url else { return }
                self?.activityIndicatorView.stopAnimating()
                self?.resourceImageView.image = image
            }
        }
    }
}
