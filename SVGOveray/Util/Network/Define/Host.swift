//
//  Host.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation

var server: Host.Server = .stage

enum Host {
    enum Server {
        case development
        case stage
        case production
    }
    
    case svgOveray(server: Server)
}

extension Host {
   
    // Raw value
    var rawValue: String {
        switch self {
    #if DEBUG
        case .svgOveray(let server):  return server.rawValue
        
    #else
        case .svgOveray(_):           return "https://github.com"
    #endif
        }
    }
    
    
    // URL
    var url: URL {
        return URL(string: self.rawValue)!
    }
    
    
    init?(rawValue: String?) {
        guard let rawValue = rawValue else { return nil }
        
        switch rawValue {
    #if DEBUG
        case Host.svgOveray(server: .development).rawValue:   self = .svgOveray(server: .development)
        case Host.svgOveray(server: .stage).rawValue:         self = .svgOveray(server: .stage)
        case Host.svgOveray(server: .production).rawValue:    self = .svgOveray(server: .production)
            
    #else
        case Host.svgOveray(server: .development).rawValue:   self = .svgOveray(server: .production)
        case Host.svgOveray(server: .stage).rawValue:         self = .svgOveray(server: .production)
        case Host.svgOveray(server: .production).rawValue:    self = .svgOveray(server: .production)
    #endif
        
        default:                                              return nil
        }
    }
}

extension Host.Server {
    
    var rawValue: String {
        switch self {
        #if DEBUG
        case .development: return "https://github.com"
        case .stage:       return "https://github.com"
        case .production:  return "https://github.com"
        
        #else
        case .development: return "https://github.com"
        case .stage:       return "https://github.com"
        case .production:  return "https://github.com"
        #endif
        }
    }
}

extension Host.Server: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension Host.Server: CustomDebugStringConvertible {
    
    var debugDescription: String {
        #if DEBUG
        switch self {
        case .development:  return "Development server"
        case .stage:        return "Stage server"
        case .production:   return "Production server"
        }
        
        #else
        return ""
        #endif
    }
}
