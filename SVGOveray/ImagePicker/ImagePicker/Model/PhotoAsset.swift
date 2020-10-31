//
//  PhotoAsset.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Photos

struct PhotoAsset: Asset {
    let asset: PHAsset
    var order: Int?
    let selectionType: SelectionType
}

extension PhotoAsset {
    
    var isSelected: Bool {
        return order != nil
    }
}
