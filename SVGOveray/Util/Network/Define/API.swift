//
//  API.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation

enum API: Equatable {
    case imageURLs
}

extension API {
    
    var url: URL {
        switch self {
        case .imageURLs:    return URL(string: "\(Host.svgOveray(server: server).rawValue)/SVGOveray/blob/master/svgs/svgs.json")!
        }
    }
}
