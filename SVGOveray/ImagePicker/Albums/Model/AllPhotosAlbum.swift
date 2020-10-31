//
//  AllPhotosAlbum.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation
import Photos

struct AllPhotosAlbum: Album {
    var title: String   = NSLocalizedString("Recent", comment: "")
    var count: UInt     = 0
    var asset: PHAsset? = nil
}

extension AllPhotosAlbum {
    
    init(data: PHFetchResult<PHAsset>) {
        title = NSLocalizedString("Recent", comment: "")
        count = UInt(data.count)
        asset = data.firstObject
    }
}
