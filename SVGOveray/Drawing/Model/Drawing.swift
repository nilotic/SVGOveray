//
//  Drawing.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

#if canImport(PencilKit)
import PencilKit
#endif


@available(iOS 13, *)
struct Drawing {
    var id: Int64?
    var data: Any?
    var asset: PHAsset?
    var image: UIImage?
}

@available(iOS 13, *)
extension Drawing: Codable {
    
    private enum Key: String, CodingKey {
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        
        guard let data = data as? PKDrawing else { return }
        do { try container.encode(data, forKey: .data) } catch { throw error }
    }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { data = try container.decode(PKDrawing.self, forKey: .data) } catch { throw DecodingError.keyNotFound(Key.data, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to get a data.")) }
        data = UIImage()
        id    = nil
        asset = nil
        image = nil
    }
}

@available(iOS 13, *)
extension Drawing: Equatable {
    
    static func == (lhs: Drawing, rhs: Drawing) -> Bool {
        return lhs.id == rhs.id
    }
}
