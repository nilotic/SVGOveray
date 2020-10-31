//
//  EditorDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation

// MARK: - Define
struct EditorNotificationName {
    static let editor = Notification.Name("EditorNotification")
}

final class EditorDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    private(set) var imageURLs = [URL]()
    
    
    // MARK: - Function
    // MARK: Public
    func requestResource() -> Bool {
        let request = URLRequest(httpMethod: .get, url: .imageURLs)
        
        return NetworkManager.shared.request(urlRequest: request) { result in
            var imageURLs     = [URL]()
            var error: Error? = nil
            
            defer {
                DispatchQueue.main.async {
                    self.imageURLs = imageURLs
                    NotificationCenter.default.post(name: EditorNotificationName.editor, object: error)
                }
            }
            
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
