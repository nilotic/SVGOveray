//
//  DrawingViewController.swift
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
@available(iOS 13.0, *)
protocol DrawingViewControllerDelegate: class {
    func didFinish(drawing: Drawing?)
}

@available(iOS 13.0, *)
final class DrawingViewController: UIViewController {
    
    // MARK: - IBOulet
    @IBOutlet private var drawingModeBarButtonItem: UIBarButtonItem!
    @IBOutlet private var undoBarButtonItem: UIBarButtonItem!
    @IBOutlet private var redoBarButtonItem: UIBarButtonItem!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    let dataManager = DrawingDataManager()
    weak var delegate: DrawingViewControllerDelegate? = nil
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    
    // MARK: Private
    private let queue = DispatchQueue(label: "DrawingSaveQueue")
    
    private lazy var canvasView: PKCanvasView = {
        let canvasView = PKCanvasView()
        canvasView.minimumZoomScale       = 1.0
        canvasView.maximumZoomScale       = 10.0
        canvasView.zoomScale              = 1.0
        canvasView.isOpaque               = false
        canvasView.bounces                = true
        canvasView.bouncesZoom            = true
        canvasView.alwaysBounceHorizontal = true
        canvasView.alwaysBounceVertical   = true
        canvasView.allowsFingerDrawing    = true
        canvasView.delegate               = self
        view.addSubview(canvasView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive   = true
        canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        canvasView.topAnchor.constraint(equalTo: view.topAnchor).isActive           = true
        
        let constant: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -110.0 : 0
        canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
        
        if let drawing = dataManager.drawing?.data as? PKDrawing {
            canvasView.drawing = drawing
            updateImage()
        }
         
        view.bringSubviewToFront(activityIndicatorView)
        return canvasView
    }()
    
    private lazy var imageView: UIImageView = {
       let imageView = UIImageView()
        imageView.frame       = .zero
        imageView.contentMode = .scaleAspectFit
        
        view.addSubview(imageView)
        view.bringSubviewToFront(canvasView)
        return imageView
    }()
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigation()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveIncomplete(notification:)),  name: DrawingNotificationName.incomplete,        object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOrientation(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dataManager.requestIncompleteDrawing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setToolPicker()
        
        DispatchQueue.main.async {
            self.updateCanvas()
            self.canvasView.becomeFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    private func setNavigation() {
        drawingModeBarButtonItem.isEnabled = UIDevice.current.userInterfaceIdiom == .pad
        drawingModeBarButtonItem.tintColor = drawingModeBarButtonItem.isEnabled == false ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : drawingModeBarButtonItem.tintColor
        
        undoBarButtonItem.isEnabled = UIDevice.current.userInterfaceIdiom == .phone
        undoBarButtonItem.tintColor = undoBarButtonItem.isEnabled == false ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : undoBarButtonItem.tintColor
        
        redoBarButtonItem.isEnabled = UIDevice.current.userInterfaceIdiom == .phone
        redoBarButtonItem.tintColor = redoBarButtonItem.isEnabled == false ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : redoBarButtonItem.tintColor
    }
    
    /// Call this function after loading a view. Because the window will be set after loading a view
    private func setToolPicker() {
        guard let window = parent?.view.window, let toolPicker = PKToolPicker.shared(for: window) else { return }
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
    }
    
    private func updateCanvas() {
        guard canvasView.bounds.size != .zero, canvasView.drawing.bounds.size != .zero else { return }
        let scale = min(canvasView.bounds.width / max(canvasView.bounds.width, canvasView.drawing.bounds.origin.x + canvasView.drawing.bounds.width), canvasView.bounds.height / max(canvasView.bounds.height, canvasView.drawing.bounds.origin.y + canvasView.drawing.bounds.height))
        
        canvasView.minimumZoomScale = scale
        canvasView.zoomScale        = scale
        
        
        // Scroll to the top.
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
        canvasView.contentSize   = CGSize(width: max(canvasView.bounds.width, canvasView.drawing.bounds.width), height: max(canvasView.bounds.height, canvasView.drawing.bounds.height))
        
        guard dataManager.imageFrame != .zero else { return }
        imageView.frame = CGRect(x: dataManager.imageFrame.origin.x * scale, y: dataManager.imageFrame.origin.y * scale, width: dataManager.imageFrame.size.width * scale, height: dataManager.imageFrame.size.height * scale)
    }
    
    private func updateImage() {
        guard let asset = dataManager.drawing?.asset else { return }
        
        activityIndicatorView.startAnimating()
        ImageDataManager.shared.load(asset: ImageAsset(asset: asset, hash: hash)) { (asset, imageData) in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                guard let asset = asset else { return }
                
                switch asset.isGIF {
                case true:
                    Toast.show(message: NSLocalizedString("GIF is not available", comment: ""))
                    
                case false:
                    guard let imageData = imageData, let image = UIImage(data: imageData) else { return }
                    self.imageView.image = image
                    
                    let scale = min(self.canvasView.bounds.width / image.size.width, self.canvasView.bounds.height / image.size.height)
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    
                    self.imageView.frame = CGRect(origin: CGPoint(x: (self.canvasView.bounds.width - size.width) / 2.0, y: (self.canvasView.bounds.height - size.height) / 2.0), size: size)
                    self.dataManager.imageFrame = self.imageView.frame
                }
            }
        }
    }
    
    
    
    // MARK: - Notification
    @objc private func didReceiveIncomplete(notification: Notification) {
        guard let drawing = notification.object as? PKDrawing else { return }
      
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: NSLocalizedString("Restore a drawing?", comment: ""), message: NSLocalizedString("The canvas didn't close correctly. Would you like to restore a drawing?", comment: ""), preferredStyle: .alert)
            let restoreAction = UIAlertAction(title: NSLocalizedString("common_ok", comment: ""), style: .default) { action in
                DispatchQueue.main.async { self.canvasView.drawing = drawing }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("common_cancel", comment: ""), style: .cancel) { action in
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.drawing)
            }
            
            alertController.addAction(restoreAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true)
        }
    }
    
    @objc private func didReceiveOrientation(notification: Notification) {
        let isChanged = (canvasView.frame.size.height < canvasView.frame.width && UIDevice.current.orientation.isPortrait) || (canvasView.frame.size.width < canvasView.frame.height && UIDevice.current.orientation.isLandscape)
        guard isChanged == true else { return }
        
        DispatchQueue.main.async { self.updateCanvas() }
    }
    
    
    
    // MARK: - Event
    @IBAction private func drawingModeBarButtonItemAction(_ sender: UIBarButtonItem) {
        canvasView.allowsFingerDrawing.toggle()
        sender.image = canvasView.allowsFingerDrawing == true ? #imageLiteral(resourceName: "fingerDrawing") : #imageLiteral(resourceName: "applePencilIconDrawing")
    }
    
    @IBAction private func undoBarButtonAction(_ sender: UIBarButtonItem) {
        canvasView.undoManager?.undo()
    }
    
    @IBAction private func redoBarButtonItemAction(_ sender: UIBarButtonItem) {
        canvasView.undoManager?.redo()
    }
    
    @IBAction private func saveBarButtonItemAction(_ sender: UIBarButtonItem) {
        dataManager.save(data: canvasView.drawing)
        
        let drawingImage = canvasView.drawing.image(from: canvasView.drawing.bounds, scale: UIScreen.main.scale)
        dataManager.drawing?.image = imageView.image != nil ? view.renderedImage : drawingImage
        
        DispatchQueue.main.async {
            self.dismiss(animated: true) { self.delegate?.didFinish(drawing: self.dataManager.drawing) }
        }
    }
    
    @IBAction private func closeBarButtonItemAction(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async { self.dismiss(animated: true) }
    }
}



// MARK: - PKCanvasView Delegate
@available(iOS 13, *)
extension DrawingViewController: PKCanvasViewDelegate {
        
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        let drawing = canvasView.drawing
        queue.async { self.dataManager.save(data: drawing) }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        imageView.frame = CGRect(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
    }
}



// MARK: - ImagePickerViewController Delegate
@available(iOS 13.0, *)
extension DrawingViewController: ImagePickerViewControllerDelegate {
    
    func didSelect(assets: [PHAsset]) {
        let asset = assets.first
        dataManager.update(asset: asset)
        
        updateImage()
    }
}
