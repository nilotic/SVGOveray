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
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    // MARK: - Value
    // MARK: Private
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBarButtonItems()
    }
    
    
    // MARK: - Function
    // MARK: Private
    func setBarButtonItems() {
        guard #available(iOS 13, *) else { return }
        pencilBarButtonItem.image = UIImage(systemName: "pencil")
        pencilBarButtonItem.isEnabled = true
    }
    
    
}
