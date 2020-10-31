//
//  ImagePickerViewController.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

// MARK: - Define
protocol ImagePickerViewControllerDelegate: class {
    func didSelect(assets: [PHAsset])
}

final class ImagePickerViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var titleButton: UIButton!
    @IBOutlet private var doneButton: UIButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    let dataManager = ImagePickerDataManager()
    weak var delegate: ImagePickerViewControllerDelegate? = nil
    
    
    // MARK: Private
    private weak var albumsViewController: AlbumsViewController? = nil
    private var beginIndexPath = IndexPath(item: 0, section: 0)
    
    private var authorizationStatus: PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigation()
        setAlbumView()
        updateTitle()
        updateButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveImages(notification:)),      name: ImagePickerNotificationName.images,        object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveUpdate(notification:)),      name: ImagePickerNotificationName.update,        object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOrientation(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        requestAssets()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ImageDataManager.shared.reset()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    
    // MARK: - Function
    // MARK: Private
    private func setNavigation() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor(named: "black") ?? #colorLiteral(red: 0.1254901961, green: 0.1411764706, blue: 0.1607843137, alpha: 1)]
    }
    
    private func setAlbumView() {
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
    }
    
    private func requestAssets() {
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization { status in
                switch status {
                case .limited, .authorized:  self.fetchAssets()
                default:                     DispatchQueue.main.async { self.dismiss(animated: true) }
                }
            }
            
        case .limited, .authorized:
            fetchAssets()
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("Allow the app to access Photos to save the image.", comment: ""), message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
                    DispatchQueue.main.async {
                        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) == true else { return }
                        UIApplication.shared.open(url, options: [:])
                    }
                }
                
                alertController.addAction(action)
                self.present(alertController, animated: true)
            }
            
        default:
            break
        }
    }
    
    private func requestAuthorization(completion: @escaping ((_ status: PHAuthorizationStatus) -> Void)) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: completion)
            
        } else {
            PHPhotoLibrary.requestAuthorization(completion)
        }
    }
    
    private func fetchAssets() {
        dataManager.fetch(album: AllPhotosAlbum())
        DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
    }
    
    private func updateTitle() {
        var titleAttributes: [NSAttributedString.Key : Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment         = .left
            paragraphStyle.lineBreakMode     = .byTruncatingTail
            paragraphStyle.minimumLineHeight = 20.0
            paragraphStyle.maximumLineHeight = 20.0
            
            return [.font            : UIFont.systemFont(ofSize: 17.0, weight: .semibold),
                    .foregroundColor : UIColor(named: "black") ?? #colorLiteral(red: 0.1254901961, green: 0.1411764706, blue: 0.1607843137, alpha: 1),
                    .paragraphStyle  : paragraphStyle]
        }
        
        titleButton.setAttributedTitle(NSAttributedString(string: dataManager.title ?? NSLocalizedString("Recent", comment: ""), attributes: titleAttributes), for: .normal)
        titleButton.semanticContentAttribute = .forceRightToLeft
    }
    
    private func updateButton() {
        var attributes: [NSAttributedString.Key : Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment         = .center
            paragraphStyle.lineBreakMode     = .byWordWrapping
            paragraphStyle.minimumLineHeight = 22.0
            paragraphStyle.maximumLineHeight = 22.0
            
            return [.font            : UIFont.systemFont(ofSize: 16.0, weight: .medium),
                    .foregroundColor : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                    .paragraphStyle  : paragraphStyle]
        }
        
        var string: String {
            switch dataManager.selectionType {
            case .single:    return "\(NSLocalizedString("Done", comment: ""))"
            case .multiple:  return "\(NSLocalizedString("Done", comment: "")) (\(dataManager.selectedAssets.count)/\(dataManager.maximumCount))"
            }
        }
        
        doneButton.setAttributedTitle(NSAttributedString(string: string, attributes: attributes), for: .normal)
        doneButton.isEnabled = !dataManager.selectedAssets.isEmpty
    }
    
    private func animate(isHidden: Bool, completion: ((Bool) -> Void)? = nil) {
        view.layoutIfNeeded()
        
        switch isHidden {
        case false:
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                self.containerView.alpha = 1.0
                self.titleButton.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
            }
            
            UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: .curveEaseIn, animations: {
                self.containerView.transform = .identity
            }, completion: completion)
            
        case true:
            UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
            }, completion: completion)
            
            
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: {
                self.containerView.alpha = 0
                self.titleButton.imageView?.transform = .identity
            }, completion: completion)
        }
    }
    
    private func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentImagePickerController()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { isGranted in
                switch isGranted {
                case true:    self.presentImagePickerController()
                case false:   DispatchQueue.main.async { self.dismiss(animated: true) }
                }
            }
            
        case .restricted, .denied:
            showPermissionAlert()
            
        default:
            DispatchQueue.main.async { self.dismiss(animated: true) }
        }
    }
    
    private func presentImagePickerController() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType    = .camera
        imagePickerController.allowsEditing = true
        imagePickerController.delegate      = self
        
        DispatchQueue.main.async { self.present(imagePickerController, animated: true) }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("App permission must be granted to use this feature. Please set App Permission as 'Allow'.", comment: ""), preferredStyle: .alert)
            let allowAction = UIAlertAction(title: NSLocalizedString("Allow", comment: ""), style: .default) { action in
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) == true else { return }
                        UIApplication.shared.open(url, options: [:])
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Deny", comment: ""), style: .cancel) { action in
                DispatchQueue.main.async { self.dismiss(animated: true) }
            }
            
            alertController.addAction(allowAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true)
        }
    }
         
    
    
    // MARK: - Notification
    @objc private func didReceiveImages(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard notification.object == nil else {
            Toast.show(message: (notification.object as? Error)?.localizedDescription)
            return
        }
        
        DispatchQueue.main.async {
            self.updateTitle()
            self.updateButton()
            self.collectionView.reloadData()
        }
    }
    
    @objc private func didReceiveUpdate(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard let indexPaths = notification.object as? [IndexPath] else {
            Toast.show(message: (notification.object as? Error)?.localizedDescription)
            return
        }
        
        UIView.performWithoutAnimation { self.collectionView.reloadItems(at: indexPaths) }
    }
    
    @objc private func didReceiveOrientation(notification: Notification) {
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }
    
    
    
    // MARK: - Event
    // MARK: Title Button
    @IBAction private func titleButtonTouchUpInside(_ sender: UIButton) {
        albumsViewController?.requestAlbums()
        
        animate(isHidden: sender.isSelected)
        sender.isSelected = !sender.isSelected
    }
    

    // MARK: Done
    @IBAction private func doneButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .curveEaseOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: nil)
    }
    
    @IBAction private func doneButtonTouchUpInside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .curveEaseIn]) {
            sender.transform = .identity
            
        } completion: { isFinished in
            DispatchQueue.main.async {
                self.dismiss(animated: true) { self.delegate?.didSelect(assets: self.dataManager.selectedAssets) }
            }
        }
    }
    
    @IBAction private func doneButtonTouchDragOutside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: {
            sender.transform = .identity
        }, completion: nil)
    }
    
    
    // MARK: Close
    @IBAction private func closeBarButtonItemAction(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async { self.dismiss(animated: true) }
    }
    
    
    // MARK: Pan Gesture
    @IBAction private func panGestureRecognizerAction(_ sender: UIPanGestureRecognizer) {
        guard dataManager.selectionType == .multiple, let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) else { return }
        
        switch sender.state {
        case .ended:    updateButton()
        default:        collectionView.reloadItems(at: dataManager.update(indexPath: indexPath, state: sender.state))
        }
    }
}



// MARK: - CollectionView
// MARK: DataSource
extension ImagePickerViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataManager.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < dataManager.images.count else { return UICollectionViewCell() }
        
        switch dataManager.images[indexPath.row] {
        case is CameraAsset:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraAssetCell.identifier, for: indexPath) as? CameraAssetCell else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: CameraAssetCell.identifier, for: indexPath)
            }
            
            return cell
            
        case let data as PhotoAsset:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoAssetCell.identifier, for: indexPath) as? PhotoAssetCell else {
                log(.error, "Failed to get a PhotoAssetCell.")
                return UICollectionViewCell()
            }
            
            cell.update(data: data)
            
            switch data.isSelected {
            case true:  collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            case false: collectionView.deselectItem(at: indexPath, animated: false)
            }
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
}


// MARK: FlowLayout
extension ImagePickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var divider: CGFloat {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:  return UIScreen.main.bounds.height < UIScreen.main.bounds.width ? 7.0 : 5.0
            default:    return 3.0
            }
        }
        
        let length = (collectionView.frame.width - (divider - 1.0) * 3.0) / divider
        return CGSize(width: length, height: length)
        
    }
}


// MARK: Delegate
extension ImagePickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < dataManager.images.count else { return false }
        
        switch dataManager.images[indexPath.row] {
        case is CameraAsset:
            requestPermission()
        
        default:
            guard dataManager.select(indexPath: indexPath) == true else { return false }
            updateButton()
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < dataManager.images.count else { return false }
        
        switch dataManager.images[indexPath.row] {
        case is CameraAsset:
            break
            
        default:
            guard dataManager.select(indexPath: indexPath) == true else { return false }
            updateButton()
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        guard dataManager.selectionType == .multiple else { return false }
        dataManager.update(indexPath: indexPath, state: .began)
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        collectionView.reloadItems(at: dataManager.update(indexPath: indexPath, state: .changed))
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        updateButton()
    }
}
    

// MARK:- UIImagePickerController Delegate
extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        DispatchQueue.main.async { picker.dismiss(animated: true) }
        
        guard dataManager.update(image: info[.editedImage] as? UIImage) == true else { return }
        DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
    }
}



// MARK: - AlbumsViewController Delegate
extension ImagePickerViewController: AlbumsViewControllerDelegate {
    
    func didSelect(album: Album?, collection: PHAssetCollection?) {
        titleButton.isSelected = false
        
        animate(isHidden: !titleButton.isSelected)
        dataManager.fetch(album: album, collection: collection)
        
        collectionView.contentOffset = .zero
    }
}



// MARK: - Segue
extension ImagePickerViewController: SegueHandlerType {
    
    // MARK: Enum
    enum SegueIdentifier: String {
        case albums = "AlbumsSegue"
    }
    
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segueIdentifier(with: segue) else {
            log(.error, "Failed to get a segueIdentifier.")
            return
        }
        
        switch segueIdentifier {
        case .albums:
            guard let viewController = segue.destination as? AlbumsViewController else { return }
            albumsViewController = viewController
            viewController.delegate = self
        }
    }
}
