//
//  TCUIView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 2/18/17.
//
//

import UIKit

/**
 The TCUIView defines a UI component in TCMaskView.
 You can change the property in TCUIView to customize the UI style of TCMaskView
 */
open class TCUIView : NSObject {
    
    /// Background color of the view
    @objc open var backgroundColor: UIColor
    
    /// Tint color of the view, inside which the color of all the buttons and icons will be set to tint color
    @objc open var tintColor: UIColor
    
    /// Highlighted color of the view, inside which the highlighted color of all the buttons and icons will be set to highlighted color
    @objc open var highlightedColor: UIColor
    
    /// Text color of the view, inside which the text color of all the labels will be set to text color
    @objc open var textColor: UIColor
    
    override init() {
        backgroundColor = UIColor()
        tintColor = UIColor()
        highlightedColor = UIColor()
        textColor = UIColor()
    }
    
    func clone() -> TCUIView {
        let retval = TCUIView()
        retval.backgroundColor = backgroundColor
        retval.tintColor = tintColor
        retval.highlightedColor = highlightedColor
        retval.textColor = textColor
        return retval
    }
}
