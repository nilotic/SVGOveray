//
//  EditorViewController.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

final class EditorViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var pencilBarButtonItem: UIBarButtonItem!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Private
    private let dataManager = EditorDataManager()
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBarButtonItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveResource(notification:)), name: EditorNotificationName.resource, object: nil)
        
        guard dataManager.requestResource() == true else { return }
        activityIndicatorView.startAnimating()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    func setBarButtonItems() {
        guard #available(iOS 13, *) else { return }
        pencilBarButtonItem.image = UIImage(systemName: "pencil")
        pencilBarButtonItem.isEnabled = true
    }
    

    
    // MARK: - Notification
    @objc private func didReceiveResource(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard notification.object == nil else {
            Toast.show(message: (notification.object as? Error)?.localizedDescription)
            return
        }
        
        DispatchQueue.main.async { self.collectionView.reloadData() }
    }
    
    
    // MARK: - Event
}



// MARK: - CollectionView
// MARK: DataSource
extension EditorViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataManager.imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < dataManager.imageURLs.count, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ResourceCell.identifier, for: indexPath) as? ResourceCell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: ResourceCell.identifier, for: indexPath)
        }
        
        cell.update(data: dataManager.imageURLs[indexPath.row])
        return cell
    }
}


// MARK: FlowLayout
extension EditorViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120.0, height: 120.0)
    }
}


// MARK: Delegate
extension EditorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < dataManager.imageURLs.count else { return }
        
        activityIndicatorView.startAnimating()
        dataManager.imageURL = ImageURL(url: dataManager.imageURLs[indexPath.row], hash: hash)
        
        ImageDataManager.shared.download(url: dataManager.imageURL) { [weak self] (url, data) in
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
        
                guard self?.dataManager.imageURL == url else { return }
                
            }
        }
    }
}


// MARK: Prefecth
extension EditorViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < dataManager.imageURLs.count else { continue }
            ImageDataManager.shared.download(url: ImageURL(url: dataManager.imageURLs[indexPath.row], hash: hash))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < dataManager.imageURLs.count else { continue }
            ImageDataManager.shared.cancel(url: ImageURL(url: dataManager.imageURLs[indexPath.row], hash: hash))
        }
    }
}



// MARK: - ScrollView Delegate
extension EditorViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}



// MARK: - ImagePickerViewController Delegate
extension EditorViewController: ImagePickerViewControllerDelegate {
    
    func didSelect(assets: [PHAsset]) {
        guard let asset = assets.first else { return }
        dataManager.assets = assets
        
        DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
        
        ImageDataManager.shared.load(asset: ImageAsset(asset: asset, hash: hash), size: imageView.frame.size) { (asset, image, info) in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.imageView.image = image
            }
        }
    }
}
        


// MARK: - Segue
extension EditorViewController: SegueHandlerType {
    
    // MARK: Enum
    enum SegueIdentifier: String {
        case image = "ImagePickerSegue"
    }
    
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segueIdentifier(with: segue) else {
            log(.error, "Failed to get a segueIdentifier.")
            return
        }
        
        switch segueIdentifier {
        case .image:
            guard let viewController = (segue.destination as? UINavigationController)?.children.first as? ImagePickerViewController else {
                log(.error, "Failed to get a ImagePickerViewController.")
                return
            }
            
            viewController.dataManager.selectedAssets = dataManager.assets
            viewController.delegate = self
        }
    }
}
