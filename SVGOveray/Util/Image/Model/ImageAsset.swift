//
//  ImageAsset.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Photos

struct ImageAsset {
    // MARK: Public
    let asset: PHAsset
    let hash: String
    
    
    // MARK: Private
    private let uuid: UUID
}

extension ImageAsset {
    
    init?(asset: PHAsset?, hash: Int) {
        guard let asset = asset else { return nil }
        self.asset = asset
        self.hash  = "\(hash)"
        
        uuid = UUID()
    }
}

extension ImageAsset: Hashable {
    
    var rawValue: String {
        return "\(uuid.uuidString)\(hash)"
    }
    
    var isGIF: Bool {
        return asset.playbackStyle == .imageAnimated
    }
}

extension ImageAsset: Equatable {
    
    static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
