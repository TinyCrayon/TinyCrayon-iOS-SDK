//
//  TCMaskViewMode.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 2/18/17.
//
//

import UIKit

/**
 TCMaskViewMode defines how the current masking result is shown to the user, the result value (v) shown to user is blended with current mask (m) by foreground image/color (f) and background image/color (b):
 
 - If inverted is false: v = f * m + b * (1 - m)
 - If inverted is true: v = f * (1 - m) + b * m
 
 For both foreground and background settings:
 
 - If image is not nil, image will be used
 - If image is nil and color is not nil, color will be used
 - If both image and color are nil, foreground will be set to a PNG transparent color and background will be set to the image of masking
 
 */
open class TCMaskViewMode : NSObject {
    /// Initialize a TCMaskViewMode
    @objc public override init() {}
    
    /// Initialize a TCMaskViewMode
    @objc public init(foregroundColor: UIColor, backgroundColor: UIColor, isInverted: Bool) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.isInverted = isInverted
    }
    
    /// Initialize a TCMaskViewMode
    @objc public init(foregroundImage: UIImage!, backgroundColor: UIColor, isInverted: Bool) {
        self.foregroundImage = foregroundImage
        self.backgroundColor = backgroundColor
        self.isInverted = isInverted
    }
    
    /// Initialize a TCMaskViewMode
    @objc public init(foregroundColor: UIColor, backgroundImage: UIImage!, isInverted: Bool) {
        self.foregroundColor = foregroundColor
        self.backgroundImage = backgroundImage
        self.isInverted = isInverted
    }
    
    /// Initialize a TCMaskViewMode
    @objc public init(foregroundImage: UIImage!, backgroundImage: UIImage!, isInverted: Bool) {
        self.foregroundImage = foregroundImage
        self.backgroundImage = backgroundImage
        self.isInverted = isInverted
    }
    
    /// Background color of TCMaskViewMode
    @objc open var backgroundColor : UIColor!
    
    /// Foreground color of TCMaskViewMode
    @objc open var foregroundColor : UIColor!
    
    /// Background image of TCMaskViewMode
    @objc open var backgroundImage : UIImage!
    
    /// Foreground image of TCMaskViewMode
    @objc open var foregroundImage : UIImage!
    
    /**
     A Boolean value that determines whether the blending between foreground and background color/image should be inverted.
     The default value is false.
     */
    @objc open var isInverted = false
    
    /**
     Create a TCMaskViewMode which looks like a PNG transparent pattern.
     
     - returns: A new TCMaskViewMode which looks like a PNG transparent pattern.
     */
    @objc public static func transparent() -> TCMaskViewMode {
        let retval = TCMaskViewMode()
        retval.isInverted = true
        return retval
    }
    
    func clone() -> TCMaskViewMode {
        let viewMode = TCMaskViewMode()
        viewMode.backgroundColor = self.backgroundColor
        viewMode.backgroundImage = self.backgroundImage?.normalize()
        viewMode.foregroundColor = self.foregroundColor
        viewMode.foregroundImage = self.foregroundImage?.normalize()
        viewMode.isInverted = self.isInverted
        return viewMode
    }
}
