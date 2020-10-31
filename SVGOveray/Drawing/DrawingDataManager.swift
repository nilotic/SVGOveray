//
//  DrawingDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

#if canImport(PencilKit)
import PencilKit
#endif

// MARK: - Define
struct DrawingNotificationName {
    static let incomplete = Notification.Name("DrawingIncompleteNotification")
}

@available(iOS 13, *)
final class DrawingDataManager: NSObject {

    // MARK: - Value
    // MARK: Public
    var drawing: Drawing?  = nil
    var imageFrame: CGRect = .zero
    
    
    // MARK: Private
    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    
    // MARK: - Function
    // MARK: Public
    func requestIncompleteDrawing() {
        guard drawing == nil, let data = UserDefaults.standard.data(forKey: UserDefaultsKey.drawing) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
              
        do {
            let incompleteDrawing = try decoder.decode(Drawing.self, from: data)
            NotificationCenter.default.post(name: DrawingNotificationName.incomplete, object: incompleteDrawing)
        } catch {}
    }
    
    func save(data: PKDrawing) {
        if self.drawing == nil {
            self.drawing = Drawing()
        }
        
        self.drawing?.data = data
        
        guard let data = self.drawing else { return }
        do { UserDefaults.standard.set(try encoder.encode(data), forKey: UserDefaultsKey.drawing) } catch {}
        UserDefaults.standard.synchronize()
    }
    
    func update(asset: PHAsset?) {
        if drawing == nil {
            drawing = Drawing()
        }
        
        drawing?.asset = asset
    }
}
