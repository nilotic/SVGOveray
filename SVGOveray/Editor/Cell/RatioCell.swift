//
//  RatioCell.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/11/01.
//

import UIKit

final class RatioCell: UICollectionViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet private var ratioLabel: UILabel!
    

    
    // MARK: - Value
    // MARK: Public
    static let identifier = "RatioCell"
    
    override var isSelected: Bool {
        didSet { layer.borderColor = isSelected == false ? UIColor(named: "title")?.cgColor : UIColor(named: "green")?.cgColor }
    }
    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10.0
        layer.borderWidth  = 1.0
        layer.borderColor  = UIColor(named: "title")?.cgColor
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func update(data: CGSize) {
        ratioLabel.text = "\(Int(data.width)) : \(Int(data.height))"
    }
}
