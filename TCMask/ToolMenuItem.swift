//
//  ToolMenuItem.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 3/4/17.
//
//

import UIKit

class ToolMenuItem : UIView {
    weak var imageView: UIImageView!
    weak var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        for subview in self.subviews {
            if let view = subview as? UIImageView {
                view.image = view.image?.withRenderingMode(.alwaysTemplate)
                self.imageView = view
            }
            else if let view = subview as? UILabel {
                self.label = view
            }
        }
        self.isAccessibilityElement = true
    }
}
