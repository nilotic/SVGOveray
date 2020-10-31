//
//  ImagePickerDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

// MARK: - Define
struct ImagePickerNotificationName {
    static let images = Notification.Name("ImagePickerNotification")
    static let update = Notification.Name("ImagePickerUpdateNotification")
}

final class ImagePickerDataManager: NSObject {

    // MARK: - Value
    // MARK: Public
    private(set) var title: String? = nil
    private(set) var images = [Asset]()
    
    var selectedAssets = [PHAsset]()
    var selectionType: SelectionType = .single
    var maximumCount: UInt = 1
    
    
    // MARK: Private
    private var assets = PHFetchResult<PHAsset>()
    private var selectedImages = [PhotoAsset]()
    private var album: Album?  = nil
    private var beginIndexPath = IndexPath(item: 0, section: 0)
    
    private let isValidSize = { (asset: PHAsset) -> Bool in
        var assetResource: PHAssetResource? {
            if #available(iOS 13, *) {
                return PHAssetResource.assetResources(for: asset).last
                
            } else {
                return PHAssetResource.assetResources(for: asset).first
            }
        }
        
        guard asset.sourceType.contains(.typeCloudShared) == false else { return true }
        
        guard let resource = assetResource, let size = resource.value(forKey: "fileSize") as? UInt64 else { return false }
        return resource.originalFilename.lowercased().contains("heic") == false ? (size / (1024 * 1024) <= 10) : (size / (1024 * 1024) <= 5)
    }



    // MARK: - DeInitializer
    deinit {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        ImageDataManager.shared.reset()
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func fetch(album: Album?, collection: PHAssetCollection? = nil) {
        guard let album = album else { return }
        let selectionType = self.selectionType
        
        // Cache
        self.album = album
        
        switch album {
        case let data as AllPhotosAlbum:
            DispatchQueue.global().async {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate       = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                
                var images: [Asset] = [CameraAsset()]
                var selectedImages  = [PhotoAsset]()
                
                let assets = PHAsset.fetchAssets(with: options)
                assets.enumerateObjects { (asset, _, _) in
                    var data = PhotoAsset(asset: asset, order: nil, selectionType: selectionType)
                    
                    if let index = self.selectedAssets.firstIndex(where: { $0 == asset }) {
                        data.order = index + 1
                        selectedImages.append(data)
                    }
                    
                    images.append(data)
                }
                
                DispatchQueue.main.async {
                    self.title          = data.title
                    self.images         = images
                    self.assets         = assets
                    self.selectedImages = selectedImages
                }
                
                DispatchQueue.main.async { NotificationCenter.default.post(name: ImagePickerNotificationName.images, object: nil) }
            }
            
        case let data as UserCollectionAlbum:
            guard let collection = collection else { return }
            
            DispatchQueue.global().async {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate       = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                
                var images         = [Asset]()
                var selectedImages = [PhotoAsset]()
                
                let assets = PHAsset.fetchAssets(in: collection, options: options)
                assets.enumerateObjects { (asset, _, _) in
                    var data = PhotoAsset(asset: asset, order: nil, selectionType: selectionType)
                    
                    if let index = self.selectedAssets.firstIndex(where: { $0 == asset }) {
                        data.order = index + 1
                        selectedImages.append(data)
                    }
                    
                    images.append(data)
                }
                
                DispatchQueue.main.async {
                    self.title          = data.title
                    self.images         = images
                    self.assets         = assets
                    self.selectedImages = selectedImages
                }
                
                DispatchQueue.main.async { NotificationCenter.default.post(name: ImagePickerNotificationName.images, object: nil) }
            }
            
        case let data as SmartAlbum:
            guard let collection = collection else { return }
            
            DispatchQueue.global().async {
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                options.predicate       = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                
                var images         = [Asset]()
                var selectedImages = [PhotoAsset]()
                
                let assets = PHAsset.fetchAssets(in: collection, options: options)
                assets.enumerateObjects { (asset, _, _) in
                    var data = PhotoAsset(asset: asset, order: nil, selectionType: selectionType)
                    
                    if let index = self.selectedAssets.firstIndex(where: { $0 == asset }) {
                        data.order = index + 1
                        selectedImages.append(data)
                    }
                    
                    images.append(data)
                }
                
                DispatchQueue.main.async {
                    self.title          = data.title
                    self.images         = images
                    self.assets         = assets
                    self.selectedImages = selectedImages
                }
                
                DispatchQueue.main.async { NotificationCenter.default.post(name: ImagePickerNotificationName.images, object: nil) }
            }
            
        default:
            return
        }
    }
    
    func select(indexPath: IndexPath) -> Bool {
        guard indexPath.row < images.count, var selectedImage = (images[indexPath.row] as? PhotoAsset) else { return false }
        
        // Check file size
        guard isValidSize(selectedImage.asset) == true  else {
            Toast.show(message: NSLocalizedString("You can upload up to 10MB.", comment: ""))
            return false
        }
        
        
        // Update assets
        var updatedIndexPaths = [IndexPath]()
        
        switch selectionType {
        case .single:
            // DO NOT Handle the event if the image is alread selected
            guard selectedImages.first(where: { $0.asset == selectedImage.asset }) == nil else { return false }
            
            // Deselect all
            for image in selectedImages {
                guard let row = images.firstIndex(where: { ($0 as? PhotoAsset)?.asset == image.asset }), var image = images[row] as? PhotoAsset else { continue }
                image.order = nil
                images[row] = image
                updatedIndexPaths.append(IndexPath(row: row, section: 0))
            }
            
            selectedAssets.removeAll()
            selectedImages.removeAll()
            
        case .multiple:
            break
        }
        
        switch selectedAssets.firstIndex(where: { $0 == selectedImage.asset }) == nil {
        case true:
            guard var data = images[indexPath.row] as? PhotoAsset, selectedAssets.count < Int(maximumCount) else { return false }
            data.order = selectedAssets.count + 1
            images[indexPath.row] = data
            
            selectedAssets.append(selectedImage.asset)
            selectedImages.append(selectedImage)
            updatedIndexPaths.append(indexPath)
            
        case false:
            guard let index = selectedAssets.firstIndex(where: { $0 == selectedImage.asset }) else { return false }
            
            selectedImage.order = nil
            images[indexPath.row] = selectedImage
            
            selectedAssets.remove(at: index)
            selectedImages.removeAll(where: { $0.asset == selectedImage.asset })
            
            updatedIndexPaths.append(indexPath)
            
            // Update orders
            for (i, image) in selectedImages.enumerated() {
                var data = image
                data.order = i + 1
                selectedImages[i] = data
            }
            
            
            // Update images
            for (row, image) in images.enumerated() {
                guard let data = image as? PhotoAsset, let first = selectedImages.first(where: { $0.asset == data.asset }), data.order != first.order else { continue }

                images[row] = first
                updatedIndexPaths.append(IndexPath(row: row, section: 0))
            }
        }
        
        NotificationCenter.default.post(name: ImagePickerNotificationName.update, object: updatedIndexPaths)
        return true
    }
    
    @discardableResult
    func update(indexPath: IndexPath, state: UIGestureRecognizer.State) -> [IndexPath] {
        switch state {
        case .began:
            beginIndexPath = indexPath
            return []
            
        case .changed:  break
        default:        return []
        }
        
        for image in selectedImages {
            guard let firstIndex = selectedAssets.firstIndex(where: { $0 == image.asset }) else { continue }
            selectedAssets.remove(at: firstIndex)
        }
        
        selectedImages.removeAll()
        
        let begin = beginIndexPath
        let end   = indexPath
        
        var updatedIndexPaths = [IndexPath]()
        
        let minimumItem = min(begin.item, end.item)
        let maximumItem = max(begin.item, end.item)
        
        let items: [Int] = begin.item <= end.item ? (0..<images.count).map { $0 } : (0..<images.count).reversed()
        
        for item in items {
            // Update selected indexPaths
            if minimumItem...maximumItem ~= Int(item) {
                guard var photoAsset = images[item] as? PhotoAsset else { continue }
                let order = selectedAssets.count + 1
                
                switch photoAsset.isSelected {
                case false:
                    // Check the maximum count
                    guard selectedAssets.count < Int(maximumCount) else { continue }
                    
                    
                    // Check file size
                    guard isValidSize(photoAsset.asset) == true  else {
                        Toast.show(message: NSLocalizedString("You can upload up to 10MB.", comment: ""))
                        return updatedIndexPaths
                    }
                    
                    // Update the asset
                    photoAsset.order = order
                    images[item] = photoAsset
                    
                    updatedIndexPaths.append(IndexPath(item: item, section: 0))
                    
                case true:
                    if photoAsset.order != order {
                        photoAsset.order = order
                        images[item] = photoAsset
                        
                        updatedIndexPaths.append(IndexPath(item: item, section: 0))
                    }
                }
                
                selectedImages.append(photoAsset)
                selectedAssets.append(photoAsset.asset)
                
            } else {    // Update deselected indexPaths
                guard var photoAsset = images[item] as? PhotoAsset, photoAsset.isSelected == true else { continue }
                photoAsset.order = nil
                images[item] = photoAsset
                
                
                if let firstIndex = selectedImages.firstIndex(where: { $0.asset == photoAsset.asset }) {
                    selectedImages.remove(at: firstIndex)
                }
                
                if let index = selectedAssets.firstIndex(where: { $0 == photoAsset.asset }) {
                    selectedAssets.remove(at: index)
                }
                
                updatedIndexPaths.append(IndexPath(item: item, section: 0))
            }
        }
        
        return updatedIndexPaths
    }
    
    func update(image: UIImage?) -> Bool {
        guard let image = image else { return false }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(image:error:contextInfo:)), nil)
        return true
    }
    
    
    // MARK: Private
    @objc private func didFinishSaving(image: UIImage, error: NSError?, contextInfo: UnsafeRawPointer) {
        guard  let album = album, error == nil else {
            log(.error, error?.localizedDescription)
            return
        }
        
        fetch(album: album)
    }
}
