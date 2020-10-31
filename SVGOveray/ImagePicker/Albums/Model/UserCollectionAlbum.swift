//
//  UserCollectionAlbum.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation
import Photos

struct UserCollectionAlbum: Album {
    var title: String
    let collection: PHAssetCollection
}

extension UserCollectionAlbum {
    
    var assets: PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate       = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        return PHAsset.fetchAssets(in: collection, options: options)
    }
}

extension UserCollectionAlbum {
    
    init?(data: PHAssetCollection) {
        guard let localizedTitle = data.localizedTitle else { return nil }
 
        title       = localizedTitle
        collection  = data
    }
}
