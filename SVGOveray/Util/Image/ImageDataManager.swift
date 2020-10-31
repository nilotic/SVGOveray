//
//  ImageDataManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Foundation
import MobileCoreServices
import Photos
import Vision

final class ImageDataManager: NSObject {
    
    // MARK: - Singleton
    static let shared = ImageDataManager()
    private override init() { super.init() }    // This prevents others from using the default initializer for this calls
    
    
    // MARK: - Value
    // MARK: Private
    private lazy var imageCache = NSCache<NSString, NSData>()
    
    private lazy var imageManager: PHCachingImageManager = {
        let imageManager = PHCachingImageManager()
        imageManager.allowsCachingHighQualityImages = true
        return imageManager
    }()
    
    private lazy var downloadSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 90
        configuration.timeoutIntervalForRequest     = 90.0
        configuration.timeoutIntervalForResource    = 90.0
        return URLSession(configuration: configuration)
    }()
    
    private var downloadTasks = [ImageURL : URLSessionDataTask]()
    private var loadTasks     = [ImageAsset : PHImageRequestID]()
    private let accessQueue   = DispatchQueue(label: "ImageDataManagerAccessQueue")
    
    private lazy var uploadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "UploadQueue"
        queue.maxConcurrentOperationCount = 10
        return queue
    }()
    
    
    // MARK: - Function
    // MARK: Public
    func download(url: ImageURL?, completion: ((_ url: ImageURL?, _ data: Data?) -> Void)? = nil) {
        guard let imageURL = url else {
            completion?(url, nil)
            return
        }
        
        accessQueue.async {
            // If the cached image exist, return the image
            if let cache = self.imageCache.object(forKey: imageURL.absoluteString) {
                completion?(imageURL, cache as Data)
                return
            }
            
            
            // Download image
            let task = self.downloadSession.dataTask(with: URLRequest(url: imageURL)) { (data, response, error) in
                guard let data = data, error == nil else { return }
                let image = (response?.url?.lastPathComponent.lowercased().hasSuffix("gif") == true ? GIF.convert(data: data) : data
                
                // Cache
                self.accessQueue.async {
                    if let image = image, let urlString = url?.absoluteString {
                        self.imageCache.setObject(image, forKey: urlString as NSString)
                    }
                    
                    completion?(imageURL, data)
                    self.downloadTasks.removeValue(forKey: imageURL)
                }
            }
           
            // Cache
            self.downloadTasks[imageURL] = task
            task.resume()
        }
    }
    
    func load(asset: ImageAsset?, size: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default, completion: @escaping ((_ asset: ImageAsset?, _ image: UIImage?, _ info: [AnyHashable : Any]?) -> Void)) {
        guard let imageAsset = asset else {
            completion(asset, nil, nil)
            return
        }
        
        accessQueue.async {
            let scale = imageAsset.isGIF == false ? UIScreen.main.scale : 1.0
            
            let options = PHImageRequestOptions()
            options.deliveryMode           = imageAsset.isGIF == false ? .opportunistic : .fastFormat
            options.resizeMode             = imageAsset.isGIF == false ? .exact : .fast
            options.isNetworkAccessAllowed = true
            
            // Request
            self.loadTasks[imageAsset] = self.imageManager.requestImage(for: imageAsset.asset, targetSize: CGSize(width: size.width * scale, height: size.height * scale), contentMode: contentMode, options: options) { (image, info) in
                completion(imageAsset, image, info)
            }
            
            // Cache
            self.imageManager.startCachingImages(for: [imageAsset.asset], targetSize: size, contentMode: contentMode, options: options)
        }
    }
    
    func load(asset: ImageAsset?, size: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default, options: PHImageRequestOptions? = nil, completion: @escaping ((_ asset: ImageAsset?, _ data: Data?) -> Void)) {
        guard let imageAsset = asset else {
            completion(asset, nil)
            return
        }
            
        accessQueue.async {
            // Load
            if #available(iOS 13, *) {
                self.loadTasks[imageAsset] = self.imageManager.requestImageDataAndOrientation(for: imageAsset.asset, options: options) { (data, _, _, _) in
                    completion(imageAsset, data)
                }
            
            } else {
                self.loadTasks[imageAsset] = self.imageManager.requestImageData(for: imageAsset.asset, options: options) { (data, _, _, _) in
                    completion(imageAsset, data)
                }
            }
            
            // Cache
            self.imageManager.startCachingImages(for: [imageAsset.asset], targetSize: size, contentMode: contentMode, options: options)
        }
    }
    
    func cancel(asset: ImageAsset?) {
        accessQueue.async {
            guard let asset = asset, let imageRequestID = self.loadTasks[asset] else { return }
            self.imageManager.cancelImageRequest(imageRequestID)
        }
    }
    
    func cancel(url: ImageURL?) {
        accessQueue.async {
            guard let url = url else { return }
            self.downloadTasks[url]?.cancel()
            self.downloadTasks.removeValue(forKey: url)
        }
    }
    
    func cancel(urls: [ImageURL]) {
        guard urls.isEmpty == false else { return }
        
        accessQueue.async {
            urls.forEach {
                self.downloadTasks[$0]?.cancel()
                self.downloadTasks.removeValue(forKey: $0)
            }
        }
    }
     
    func reset() {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        imageManager.stopCachingImagesForAllAssets()
    }
}

