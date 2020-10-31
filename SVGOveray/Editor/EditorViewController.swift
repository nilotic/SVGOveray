//
//  EditorViewController.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

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
        
        DispatchQueue.main.async {
            self.collectionView.contentOffset.x = 0
            self.collectionView.reloadData()
        }
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
        return CGSize(width: 128.0, height: 128.0)
    }
}


// MARK: Delegate
extension EditorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < dataManager.imageURLs.count else { return }
        
        activityIndicatorView.startAnimating()
        dataManager.imageURL = ImageURL(url: dataManager.imageURLs[indexPath.row], hash: hash)
        
        ImageDataManager.shared.download(url: dataManager.imageURL) { [weak self] (url, image) in
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
        
                guard self?.dataManager.imageURL == url else { return }
                self?.imageView.image = image
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
            ImageDataManager.shared.cancelDownload(url: ImageURL(url: dataManager.imageURLs[indexPath.row], hash: hash))
        }
    }
}
