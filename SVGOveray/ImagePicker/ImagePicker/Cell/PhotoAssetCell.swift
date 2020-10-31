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
    @IBOutlet private var coverView: UIView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!


    
    // MARK: - Value
    // MARK: Public
    static let identifier = "PhotoAssetCell"
    
    
    // MARK: Private
    private var asset: ImageAsset? = nil

    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderWidth = 3.0
        layer.borderColor = UIColor.clear.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    
        ImageDataManager.shared.cancel(asset: asset)
    }
    
    
        
    // MARK: - Function
    // MARK: Public
    func update(data: PhotoAsset) {
        // Border
        layer.borderColor = data.isSelected == false ? UIColor.clear.cgColor : (UIColor(named: "green") ?? #colorLiteral(red: 0.03921568627, green: 0.8588235294, blue: 0.7215686275, alpha: 1))?.cgColor
        
        
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
