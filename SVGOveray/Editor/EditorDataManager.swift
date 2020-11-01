//
//  EditorDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation
import Photos

// MARK: - Define
struct EditorNotificationName {
    static let resource = Notification.Name("EditorResourceNotification")
}

final class EditorDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    private(set) var imageURLs = [URL]()
    private(set) var ratios    = [CGSize]()
    
    var imageURL: ImageURL? = nil
    var assets = [PHAsset]()
    
    
    // MARK: - Function
    // MARK: Public
    func request() -> Bool {
        var ratios    = [CGSize]()
        var imageURLs = [URL]()
        var error: Error? = nil
        
        
        let group = DispatchGroup()
        
        // Ratios
        group.enter()
        guard requestRatios(completion: { data in
            ratios = data
            group.leave()
            
        }) == true else {
            group.leave()
            return false
        }
        
        
        // Resource
        group.enter()
        guard requestResource(completion: { (data, requestError) in
            imageURLs = data
            error     = requestError
            
            group.leave()
            
        }) == true else {
            group.leave()
            return false
        }
        
        
        // Handling
        group.notify(queue: .main) {
            self.ratios    = ratios
            self.imageURLs = imageURLs
            NotificationCenter.default.post(name: EditorNotificationName.resource, object: error)
        }
        
        return true
    }
    
    
    // MARK: Private
    private func requestRatios(completion: @escaping ((_ ratios: [CGSize]) -> Void) ) -> Bool {
        DispatchQueue.global().async {
            let ratios = [CGSize(width: 1.0, height: 1.0), CGSize(width: 16.0, height: 9.0), CGSize(width: 3.0, height: 2.0), CGSize(width: 4.0, height: 3.0),
                          CGSize(width: 5.0, height: 4.0), CGSize(width: 4.0, height: 5.0), CGSize(width: 2.0, height: 3.0), CGSize(width: 9.0, height: 16.0)]
            
            completion(ratios)
        }
        
        return true
    }
    
    private func requestResource(completion: @escaping (_ urls: [URL], _ error: Error?) -> Void) -> Bool {
        let request = URLRequest(httpMethod: .get, url: .imageURLs)
        
        return NetworkManager.shared.request(urlRequest: request) { result in
            var imageURLs     = [URL]()
            var error: Error? = nil
            
            defer { completion(imageURLs, error) }
            
            switch result {
            case .success(let response):
                guard let decodableData = response.data else {
                    error = NetworkError(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
                    return
                }
                
                do {
                    imageURLs = try JSONDecoder().decode(ResourceResponse.self, from: decodableData).imageURLs
                    
                } catch (let decodingError) {
                    error = decodingError
                }
                
            case .failure(let networkError):
                error = networkError
            }
        }
    }
}
