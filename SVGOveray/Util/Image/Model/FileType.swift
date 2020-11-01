//
//  FileType.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/11/01.
//

import Foundation
import MobileCoreServices

enum FileType {
    case none
    case image
    case video
}

extension FileType {
    
    init(url: URL?) {
        guard let url = url, let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)?.takeRetainedValue() else {
            self = .none
            return
        }
        
        let format = url.pathExtension.components(separatedBy: ".").last ?? ""
        
        if (UTTypeConformsTo(uti, kUTTypeImage) || UTTypeConformsTo(uti, kUTTypeJPEG) || UTTypeConformsTo(uti, kUTTypeJPEG2000) ||
            UTTypeConformsTo(uti, kUTTypeTIFF) || UTTypeConformsTo(uti, kUTTypePICT) || UTTypeConformsTo(uti, kUTTypeGIF) ||
            UTTypeConformsTo(uti, kUTTypePNG) || UTTypeConformsTo(uti, kUTTypeQuickTimeImage) || UTTypeConformsTo(uti, kUTTypeAppleICNS) ||
            UTTypeConformsTo(uti, kUTTypeBMP) || UTTypeConformsTo(uti, kUTTypeICO) || UTTypeConformsTo(uti, kUTTypeRawImage) ||
            UTTypeConformsTo(uti, kUTTypeScalableVectorGraphics) || UTTypeConformsTo(uti, kUTTypeLivePhoto)) {
            self = .image
            
        } else if (UTTypeConformsTo(uti, kUTTypeVideo) || UTTypeConformsTo(uti, kUTTypeMovie) || UTTypeConformsTo(uti, kUTTypeQuickTimeMovie) ||
                   UTTypeConformsTo(uti, kUTTypeMPEG) || UTTypeConformsTo(uti, kUTTypeMPEG2Video) || UTTypeConformsTo(uti, kUTTypeMPEG2TransportStream) ||
                   UTTypeConformsTo(uti, kUTTypeMPEG4) || UTTypeConformsTo(uti, kUTTypeAppleProtectedMPEG4Video) || UTTypeConformsTo(uti, kUTTypeAVIMovie) ||
                    format == "vob" || format == "mkv" || format == "mts" || format == "webm") {
            self = .video
            
        } else {
            self = .none
        }
    }
    
    init(uti: String?) {
        let uti = (uti ?? "") as CFString
        
        if (UTTypeConformsTo(uti, kUTTypeImage) || UTTypeConformsTo(uti, kUTTypeJPEG) || UTTypeConformsTo(uti, kUTTypeJPEG2000) ||
            UTTypeConformsTo(uti, kUTTypeTIFF) || UTTypeConformsTo(uti, kUTTypePICT) || UTTypeConformsTo(uti, kUTTypeGIF) ||
            UTTypeConformsTo(uti, kUTTypePNG) || UTTypeConformsTo(uti, kUTTypeQuickTimeImage) || UTTypeConformsTo(uti, kUTTypeAppleICNS) ||
            UTTypeConformsTo(uti, kUTTypeBMP) || UTTypeConformsTo(uti, kUTTypeICO) || UTTypeConformsTo(uti, kUTTypeRawImage) ||
            UTTypeConformsTo(uti, kUTTypeScalableVectorGraphics) || UTTypeConformsTo(uti, kUTTypeLivePhoto)) {
            self = .image
            
        } else if (UTTypeConformsTo(uti, kUTTypeVideo) || UTTypeConformsTo(uti, kUTTypeMovie) || UTTypeConformsTo(uti, kUTTypeQuickTimeMovie) ||
                   UTTypeConformsTo(uti, kUTTypeMPEG) || UTTypeConformsTo(uti, kUTTypeMPEG2Video) || UTTypeConformsTo(uti, kUTTypeMPEG2TransportStream) ||
                   UTTypeConformsTo(uti, kUTTypeMPEG4) || UTTypeConformsTo(uti, kUTTypeAppleProtectedMPEG4Video) || UTTypeConformsTo(uti, kUTTypeAVIMovie)) {
            self = .video
            
        } else {
            self = .none
        }
    }
}
