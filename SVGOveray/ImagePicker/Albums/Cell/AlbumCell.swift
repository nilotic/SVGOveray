//
//  AlbumCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

final class AlbumCell: UITableViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet private var photoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var countLabel: UILabel!
    @IBOutlet private var checkImageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "AlbumCell"
    
    override var isSelected: Bool {
        didSet { checkImageView.isHighlighted = isSelected }
    }
    
    
    // MARK: Private
    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale      = LocaleManager.locale
        return numberFormatter
    }()
    
    private var asset: ImageAsset? = nil
    
    
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        checkImageView.isHighlighted = false
        ImageDataManager.shared.cancel(asset: asset)
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func update(data: Album) {
        switch data {
        case let data as AllPhotosAlbum:        update(title: data.title, count: data.count, asset: data.asset)
        case let data as UserCollectionAlbum:   update(title: data.title, count: UInt(data.assets.count), asset: data.assets.firstObject)
        case let data as SmartAlbum:            update(title: data.title, count: UInt(data.assets.count), asset: data.assets.firstObject)
        default:                                break
        }
    }
    
    
    // MARK: Private
    private func update(title: String, count: UInt, asset: PHAsset?) {
        // Title
        titleLabel.text = title
        
        
        // Count
        countLabel.text = numberFormatter.string(for: count) ?? "\(count)"
        
        
        // Image
        guard self.asset?.asset.localIdentifier != asset?.localIdentifier else { return }
        self.asset = ImageAsset(asset: asset, hash: hash)
        let size = photoImageView.frame.size
        
        photoImageView.image = nil
        activityIndicatorView.startAnimating()
        
        DispatchQueue.global().async {
            ImageDataManager.shared.load(asset: self.asset, size: size, contentMode: .aspectFill) { [weak self] (requestedAsset, image, info) in
                DispatchQueue.main.async { self?.activityIndicatorView.stopAnimating() }
                guard let image = image else { return }
                
                DispatchQueue.main.async {
                    guard self?.asset == requestedAsset else { return }
                    self?.photoImageView.image = image
                }
            }
        }
    }
}
