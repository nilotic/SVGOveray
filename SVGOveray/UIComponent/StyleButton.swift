//
//  StyleButton.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import UIKit

@IBDesignable final class StyleButton: UIButton {
    
    // MARK: - IBInspectable
    @IBInspectable var widthInset: CGFloat = 0
    
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get { return layer.cornerRadius }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable var defaultBorderColor: UIColor = .clear {
        didSet {
            defaultCacheBorderColor = defaultBorderColor
            layer.borderColor = isEnabled == true ? defaultCacheBorderColor.cgColor : disabledCacheBorderColor.cgColor
        }
    }
    
    @IBInspectable var disabledBorderColor: UIColor = .clear {
        didSet {
            disabledCacheBorderColor = disabledBorderColor
            layer.borderColor = isEnabled == true ? defaultCacheBorderColor.cgColor : disabledCacheBorderColor.cgColor
        }
    }
    
    // Background color
    @IBInspectable var defaultBackgroundColor: UIColor = .clear {
        didSet { setBackgroundImage(defaultImage, for: .normal) }
    }
    
    @IBInspectable var highlightedBackgroundColor: UIColor? = nil {
        didSet { setBackgroundImage(highlightedImage, for: .highlighted) }
    }
    
    @IBInspectable var selectedBackgroundColor: UIColor? = nil {
        didSet { setBackgroundImage(selectedImage, for: .selected) }
    }
    
    @IBInspectable var disabledBackgroundColor: UIColor = .clear {
        didSet { setBackgroundImage(disabledImage, for: .disabled) }
    }
    
    
    // MARK: - Value
    // MARK: Public
    override var isEnabled: Bool {
        didSet { layer.borderColor = isEnabled == true ? defaultBorderColor.cgColor : disabledBorderColor.cgColor }
    }
    
    override var intrinsicContentSize: CGSize {
        if let string = title(for: .normal) {
            let font = titleLabel?.font ?? UIFont.systemFont(ofSize: 14.0)
            let size = string.boundingRect(with: CGSize(width: frame.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font : font], context: nil).size
            return CGSize(width: size.width + 60.0 + widthInset, height: size.height + 23.0)
        
        } else if let attributedTitle = attributedTitle(for: .normal) {
            let size = attributedTitle.string.boundingRect(with: CGSize(width: frame.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributedTitle.attributes(at: 0, effectiveRange: nil), context: nil).size
            return CGSize(width: size.width + 60.0 + widthInset, height: size.height + 23.0)
        }
        
        return super.intrinsicContentSize
    }
    
    
    // MARK: Private
    private var defaultCacheBorderColor: UIColor = .clear
    private var disabledCacheBorderColor: UIColor = .clear
    
    
    private var defaultImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        // If the frame is zero, the context will be nil.
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setFillColor(defaultBackgroundColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private var highlightedImage: UIImage? {
        guard let backgourndColor = highlightedBackgroundColor else { return nil }
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        // If the frame is zero, the context will be nil.
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setFillColor(backgourndColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private var selectedImage: UIImage? {
        guard let backgourndColor = selectedBackgroundColor else { return nil }
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        // If the frame is zero, the context will be nil.
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setFillColor(backgourndColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private var disabledImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        // If the frame is zero, the context will be nil.
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.setFillColor(disabledBackgroundColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    
    // MARK: - Initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setButton()
    }
    
    override func prepareForInterfaceBuilder() {
        setButton()
    }
    
    
    // MARK: - Function
    // MARK: Private
    private func setButton() {
        backgroundColor = .clear
        
        layer.cornerRadius = cornerRadius
        layer.borderWidth  = borderWidth
        layer.borderColor  = isEnabled == true ? defaultCacheBorderColor.cgColor : disabledCacheBorderColor.cgColor
        
        // Background color
        setBackgroundImage(defaultImage,  for: .normal)
        setBackgroundImage(disabledImage, for: .disabled)
        
        if let highlightedImage = highlightedImage  { setBackgroundImage(highlightedImage, for: .highlighted) }
        if let selectedImage = selectedImage        { setBackgroundImage(selectedImage,    for: .selected) }
    }
}
