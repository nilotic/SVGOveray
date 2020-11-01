//
//  AlbumsDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation
import Photos

// MARK: - Define
struct AlbumsNotificationName {
    static let update = Notification.Name("AlbumsUpdated")
}

final class AlbumsDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    private(set) var allPhotos       = PHFetchResult<PHAsset>()
    private(set) var userCollections = PHFetchResult<PHAssetCollection>()
    private(set) var smartAlbums     = [PHFetchResult<PHAssetCollection>]()
    
    private(set) var albums = [Album]()
    
    //Cache
    private(set) var selectedAlbum: Album? = nil
    
    
    
    // MARK: - Initializer
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    
    // MARK: - Function
    // MARK: Public
    func requestAlbums() {
        var allPhotos       = PHFetchResult<PHAsset>()
        var userCollections = PHFetchResult<PHAssetCollection>()
        var smartAlbums     = [PHFetchResult<PHAssetCollection>]()
        
        let group = DispatchGroup()
        
        // All assets
        group.enter()
        DispatchQueue.global().async {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            allPhotosOptions.predicate       = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            
            allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
            group.leave()
        }
        
            
        // folder from User's and 3rd party's
        group.enter()
        DispatchQueue.global().async {
            userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumUserLibrary, options: nil)
            group.leave()
        }
             
        
        // group from photo app
        group.enter()
        DispatchQueue.global().async {
            let subtypes: [PHAssetCollectionSubtype] = [.smartAlbumFavorites, .smartAlbumAnimated, .smartAlbumPanoramas, .smartAlbumSelfPortraits, .smartAlbumScreenshots, .smartAlbumRecentlyAdded]
            smartAlbums = subtypes.map { PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: $0, options: nil) }
            group.leave()
        }
        

        group.notify(queue: .global()) {
            var albums = [Album]()
            let allPhotosAlbum = AllPhotosAlbum(data: allPhotos)
            
            if 0 < allPhotos.count, 0 < allPhotosAlbum.count {
                albums.append(allPhotosAlbum)
            }
            
            if 0 < userCollections.count {
                for index in 0..<userCollections.count {
                    guard let album = UserCollectionAlbum(data: userCollections.object(at: index)), 0 < album.assets.count else { continue }
                    albums.append(album)
                }
            }
            
            if 0 < smartAlbums.count {
                for index in 0..<smartAlbums.count {
                    guard let data = smartAlbums[index].firstObject, let album = SmartAlbum(data: data), 0 < album.assets.count else { continue }
                    albums.append(album)
                }
            }
            
            self.albums = albums
            NotificationCenter.default.post(name: AlbumsNotificationName.update, object: nil)
        }
    }
    
    func select(indexPath: IndexPath) -> Bool {
        guard indexPath.row < albums.count else { return false }
        selectedAlbum = albums[indexPath.row]
        return true
    }
}


// MARK: PHPhotoLibraryChangeObserver
extension AlbumsDataManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                allPhotos = changeDetails.fetchResultAfterChanges
            }
            
            smartAlbums = smartAlbums.map { changeInstance.changeDetails(for: $0)?.fetchResultAfterChanges ?? $0 }
            
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
            }
        
            NotificationCenter.default.post(name: AlbumsNotificationName.update, object: nil)
        }
    }
}

