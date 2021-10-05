//
//  TCMaskViewDelegate.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 3/2/17.
//
//

import UIKit

/**
 Delegate methods for TCMaskView, which includes:
 
 - tcMaskViewDidExit: is called after TCMaskView exits
 - tcMaskViewDidComplete: is called after a popup TCMaskView completes
 - tcMaskViewWillPushViewController: is called before navigation controller is about to accomplish TCMaskView and process to the next UIViewController
 */
@objc public protocol TCMaskViewDelegate{
    /**
     Called when the user taps 'X' button and TCMaskView exits.
     
     - parameter mask: Image masking result
     - parameter image: The original image provided to TCMaskView when 'present' was called
     */
    @objc optional func tcMaskViewDidExit(mask: TCMask, image: UIImage)
    
    /**
     Called when the user taps '✓' button and TCMaskView completes.
     
     - parameter mask: Image masking result
     - parameter image: The original image provided to TCMaskView when 'present' was called
     */
    @objc optional func tcMaskViewDidComplete(mask: TCMask, image: UIImage)
    
    /**
     Called when the user taps '->' button and UINavigationController is about to process to next UIViewController.
     
     - parameter mask: Image masking result
     - parameter image: The original image provided to TCMaskView when 'present' was called
     
     - returns: The next UIViewController where UINavigationController is about to process to
     */
    @objc optional func tcMaskViewWillPushViewController(mask: TCMask, image: UIImage) -> UIViewController!
}
