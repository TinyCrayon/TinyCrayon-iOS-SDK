//
//  ToolBarItem.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 7/31/16.
//
//

import UIKit

enum ToolBarItemType {
    case button, state, flip
}

class ToolBarItem : UIView {
    static let iconTop: CGFloat = 9
    static let iconWidth: CGFloat = 30
    static let iconHeight: CGFloat = 30
    
    static let labelTop: CGFloat = 40
    static let labelHeight: CGFloat = 18
    
    weak var label: UILabel!
    weak var imageView: UIImageView!
    var action: ((_ sender: ToolBarItem) -> ())!
    
    var color = UIColor.clear
    var textColor = UIColor.clear
    var highlightedColor = UIColor.clear
    
    var onImage: UIImage!
    var offImage: UIImage!
    
    var onText: String!
    var offText: String!
    
    
    var type: ToolBarItemType = .button
    
    var on: Bool = false {
        didSet {
            if (self.type == .state) {
                _highlighted = on
            }
            else if (self.type == .flip) {
                _highlighted = false
                self.imageView?.image = on ? onImage : offImage
                self.label.text = on ? onText : offText
            }
            else {
                assert(false)
            }
        }
    }
    
    var _highlighted: Bool = false {
        didSet {
            if (_highlighted) {
                imageView.tintColor = highlightedColor
                label.textColor = highlightedColor
            }
            else {
                imageView?.tintColor = color
                label.textColor = textColor
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        for subview in self.subviews {
            if let view = subview as? UIImageView {
                if (view.width > 20 && view.height > 20) {
                    view.image = view.image!.withRenderingMode(.alwaysTemplate)
                    self.imageView = view
                }
            }
            else if let view = subview as? UILabel {
                self.label = view
            }
        }
        self.isAccessibilityElement = true
    }
    
    func refresh() {
        self.imageView?.tintColor = color
        self.label.textColor = textColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _highlighted = !_highlighted
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.type == .button) {
            _highlighted = !_highlighted
        }
        else {
            self.on = !self.on
        }
        action?(self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
}
