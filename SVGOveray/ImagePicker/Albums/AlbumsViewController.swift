//
//  AlbumsViewController.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit
import Photos

// MARK: - Define
protocol AlbumsViewControllerDelegate: class {
    func didSelect(album: Album?, collection: PHAssetCollection?)
}

final class AlbumsViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    let dataManager = AlbumsDataManager()
    weak var delegate: AlbumsViewControllerDelegate? = nil
    
    
    
    // MARK: Private
    private var titleAttributes: [NSAttributedString.Key : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment         = .left
        paragraphStyle.lineBreakMode     = .byTruncatingTail
        paragraphStyle.minimumLineHeight = 20.0
        paragraphStyle.maximumLineHeight = 20.0
        
        return [.font            : UIFont.systemFont(ofSize: 16.0),
                .foregroundColor : UIColor(named: "textLightBlack") ?? #colorLiteral(red: 0.2039215686, green: 0.2274509804, blue: 0.2509803922, alpha: 1),
                .paragraphStyle  : paragraphStyle]
    }
    
    private var countAttributes: [NSAttributedString.Key : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment         = .left
        paragraphStyle.lineBreakMode     = .byTruncatingTail
        paragraphStyle.minimumLineHeight = 18.0
        paragraphStyle.maximumLineHeight = 18.0
        
        return [.font            : UIFont.systemFont(ofSize: 15.0),
                .foregroundColor : UIColor(named: "gray400") ?? #colorLiteral(red: 0.5294117647, green: 0.5568627451, blue: 0.5882352941, alpha: 1),
                .paragraphStyle  : paragraphStyle]
    }
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveAlbumsUpdated(notification:)), name: AlbumsNotificationName.update, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func requestAlbums() {
        DispatchQueue.global().async { self.dataManager.requestAlbums() }
        DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
    }
    
    
    
    // MARK: - Notification
    @objc private func didReceiveAlbumsUpdated(notification: Notification) {
        DispatchQueue.main.async {
            self.activityIndicatorView.stopAnimating()
            self.tableView.reloadData()
        }
    }
}



// MARK: - UITableView
// MARK: DataSource
extension AlbumsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataManager.albums.count, let cell = tableView.dequeueReusableCell(withIdentifier: AlbumCell.identifier, for: indexPath) as? AlbumCell else { return UITableViewCell() }
        let data = dataManager.albums[indexPath.row]
        cell.update(data: data)
        
        if data.title == dataManager.selectedAlbum?.title {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        return cell
    }
}


// MARK: Delegate
extension AlbumsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 13.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard dataManager.select(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) as? AlbumCell else { return nil }
        cell.isSelected = true
        
        switch dataManager.albums[indexPath.row] {
        case let data as AllPhotosAlbum:         delegate?.didSelect(album: data, collection: nil)
        case let data as UserCollectionAlbum:    delegate?.didSelect(album: data, collection: data.collection)
        case let data as SmartAlbum:             delegate?.didSelect(album: data, collection: data.collection)
        default:                                 return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AlbumCell else { return }
        cell.isSelected = false
    }
}
