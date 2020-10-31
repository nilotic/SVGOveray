//
//  ResourceResponse.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation

struct ResourceResponse {
    let imageURLs: [URL]
}

extension ResourceResponse: Decodable {
   
    private enum Key: String, CodingKey {
        case urls
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { imageURLs = try container.decode([URL].self, forKey: .urls) } catch { imageURLs = [] }
    }
}
