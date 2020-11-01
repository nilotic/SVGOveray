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
    private let dataManager  = EditorDataManager()
    private var stickerViews = [Int: StickerView]()
    
    private weak var stickerView: StickerView? = nil
    private var stickerTrasnform = CGAffineTransform()
    
    
    
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
    private func setBarButtonItems() {
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
    @IBAction private func removeButtonTouchUpInside(_ sender: UIButton) {
        stickerViews[sender.tag]?.removeFromSuperview()
        stickerViews.removeValue(forKey: sender.tag)
    }
    
    @IBAction private func panGestureRecognizerAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let view = sender.view, let hash = (view.hitTest(sender.location(in: view), with: nil))?.hash, let stickerView = stickerViews[hash] else { return }
            imageView.bringSubviewToFront(stickerView)
            
            // Cache
            self.stickerView = stickerView
            stickerTrasnform = stickerView.transform
            
        case .changed:
            guard let stickerView = stickerView else { return }
            let translation = sender.translation(in: imageView)
            let ratio = 2.0 - stickerView.transform.a
            
            stickerView.transform = stickerTrasnform.translatedBy(x: translation.x * ratio, y: translation.y * ratio)
            
            
            // Limit
            if stickerView.frame.origin.x < 0 {
                stickerView.transform.tx = (stickerView.frame.width - imageView.frame.size.width) / 2.0
            }
            
            if imageView.frame.width < (stickerView.frame.origin.x + stickerView.frame.width - 15.0) {
                stickerView.transform.tx = (imageView.frame.width - stickerView.frame.size.width) / 2.0 + 15.0
            }
            
            if stickerView.frame.origin.y <= 0 {
                stickerView.transform.ty = (stickerView.frame.height - imageView.frame.height) / 2.0
            }
            
            if imageView.frame.height <= (stickerView.frame.origin.y + stickerView.frame.height - 15.0) {
                stickerView.transform.ty = (imageView.frame.height - stickerView.frame.height) / 2.0  + 15.0
            }
            
        case .ended:
            stickerView = nil
            
        default:
            break
        }
    }
    
    @IBAction private func pinchGestureRecognizerAction(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let view = sender.view, let hash = (view.hitTest(sender.location(in: view), with: nil))?.hash, let stickerView = stickerViews[hash] else { return }
            imageView.bringSubviewToFront(stickerView)
            
            // Cache
            self.stickerView = stickerView
            stickerTrasnform = stickerView.transform
            
        case .changed:
            guard let stickerView = stickerView else { return }
            stickerView.transform = stickerTrasnform.scaledBy(x: sender.scale, y: sender.scale)
            
        case .ended:
            stickerView = nil
            
        default:
            break
        }
    }
    
    @IBAction private func rotationGestureRecognizerAction(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            guard let view = sender.view, let hash = (view.hitTest(sender.location(in: view), with: nil))?.hash, let stickerView = stickerViews[hash] else { return }
            imageView.bringSubviewToFront(stickerView)
            
            // Cache
            self.stickerView = stickerView
            stickerTrasnform = stickerView.imageView.transform
            
        case .changed:
            guard let stickerView = stickerView else { return }
            stickerView.imageView.transform = stickerTrasnform.rotated(by: sender.rotation)
            
        case .ended:
            stickerView = nil
            
        default:
            break
        }
    }
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? ResourceCell,
              let stickerView = UINib(nibName: StickerView.identifier, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? StickerView else { return }
        
        // Center position
        let size = CGSize(width: cell.frame.width * 2.0, height: cell.frame.height * 2.0)
        stickerView.frame = CGRect(x: (imageView.frame.width - size.width) / 2.0, y: (imageView.frame.height - size.height) / 2.0, width: size.width, height: size.height)
        
        
        // Image
        stickerView.imageView.image = cell.imageView.image
        
        
        // Delete Button
        stickerView.deleteButton.addTarget(self, action: #selector(removeButtonTouchUpInside(_:)), for: .touchUpInside)
        stickerView.deleteButton.tag = stickerView.hash
        
        
        // Cache
        stickerViews[stickerView.hash] = stickerView
        
        
        // Add
        imageView.addSubview(stickerView)
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



// MARK: - UIGestureRecognizer Delegate
extension EditorViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = gestureRecognizer.view else { return false }
        return stickerViews.keys.contains(view.hash)
    }
}



// MARK: - ImagePickerViewController Delegate
extension EditorViewController: ImagePickerViewControllerDelegate {
    
    func didSelect(assets: [PHAsset]) {
        guard let asset = assets.first else { return }
        let fileType = FileType(uti: asset.value(forKey: "uniformTypeIdentifier") as? String)
        
        switch fileType {
        case .image:
            dataManager.assets = assets
            
            DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
            
            // Load the selected asset
            ImageDataManager.shared.load(asset: ImageAsset(asset: asset, hash: hash), size: imageView.frame.size) { (asset, image, info) in
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.imageView.image = image
                }
            }
            
        default:
            Toast.show(message: NSLocalizedString("Unsupported \(fileType)", comment: ""))
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
