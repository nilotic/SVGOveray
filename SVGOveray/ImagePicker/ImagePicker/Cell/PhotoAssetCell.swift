//
//  PhotoAssetCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

final class PhotoAssetCell: UICollectionViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var checkerImageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!


    
    // MARK: - Value
    // MARK: Public
    static let identifier = "PhotoAssetCell"
    
    
    // MARK: Private
    private var asset: ImageAsset? = nil

    
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
    
        ImageDataManager.shared.cancelLoad(asset: asset)
    }
    
    
        
    // MARK: - Function
    // MARK: Public
    func update(data: PhotoAsset) {
        // Checker
        checkerImageView.isHighlighted = data.isSelected
        
        
        // Image
        guard data.asset.localIdentifier != asset?.asset.localIdentifier else { return }
        asset = ImageAsset(asset: data.asset, hash: hash)
        
        imageView.image = nil
        activityIndicatorView.startAnimating()
        
        ImageDataManager.shared.load(asset: asset, size: imageView.frame.size) { [weak self] (requestedAsset, image, info) in
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
                
                guard self?.asset == requestedAsset else { return }
                self?.imageView.image = image
            }
        }
    }
}
