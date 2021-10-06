//
//  TCMask.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/12/16.
//
//

import UIKit
import TCCore

/**
 TCMask is the masking result from TCMaskView
 */
@objcMembers
open class TCMask : NSObject {
    
    /// Data of masking result
    public let data: [UInt8]
    
    /// Size of mask
    public let size: CGSize
    
    /// Initialize a TCMask
    public init(data: [UInt8], size: CGSize) {
        self.data = data
        self.size = size
    }
    
    /**
     Create a gray scale UIImage from mask

     - returns: Gray scale image converted from mask
     */
     open func grayScaleImage() -> UIImage {
        var maskData = data
        let width = Int(size.width)
        let height = Int(size.height)
        let ctx = CGContext(data: &maskData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        return UIImage(cgImage: ctx.makeImage()!)
    }
    
    /**
     Create a RGBA UIImage from mask

     - returns: RGBA image converted from mask, with the alpha info of premultiplied last. If a pixel value of mask is v, the corrosponding pixel value of returned RGBA image is (v, v, v, v)
     */
    open func rgbaImage() -> UIImage {
        return TCCore.image(fromAlpha: data, size: size)
    }
    
    /**
     Create a new mask which is the inversion of the original mask     
     */
    open func inverted() -> TCMask {
        var invertedData = [UInt8](repeating: 0, count: data.count)
        TCCore.invertAlpha(&invertedData, count: invertedData.count)
        return TCMask(data: invertedData, size: size)
    }
    
    /**
     Cutout a image using mask
     
     - parameter image: Image to cutout
     - parameter resize: Specify true to resize the output image to fit the result size
     
     - returns: Nil if resize is set to true and mask only contains 0, otherwise image with cutout
     */
    open func cutout(image: UIImage, resize: Bool) -> UIImage? {
        var rect = CGRect()
        return cutout(image: image, resize: resize, outputRect: &rect)
    }
    
    /**
     Cutout an image using mask
     
     - parameter image: Image to cutout
     - parameter resize: Specify true to resize the output image to fit the result size
     - parameter outputRect: OUT parameter, which returns The rect of output image in original image. If the result image is nil, outputRect will be (0, 0, 0, 0); If resize is set to false, outputRect will be (0, 0, image.width, image.height)
     
     - returns: Nil if resize is set to true and mask only contains 0, result image with cutout otherwise
     */
    open func cutout(image: UIImage, resize: Bool, outputRect: inout CGRect) -> UIImage? {
        assert(image.size == self.size, "image size is not equal to mask size")
        var offset = CGPoint()
        let retval = TCCore.image(withAlpha: image.normalize(), alpha: data, compact: resize, offset: &offset)
        if retval == nil {
            outputRect = CGRect()
        }
        else {
            outputRect = CGRect(origin: offset, size: retval!.size)
        }
        return retval
    }
    
    /**
     Create an image blended with mask
     
     - parameter foregroundImage: Foregournd image, image size should match mask size
     - parameter backgroundImage: Background image, image size should match mask size
     
     - returns: Blended image
     */
    open func blend(foregroundImage: UIImage, backgroundImage: UIImage) -> UIImage {
        assert(foregroundImage.size == self.size, "foreground image size is not equal to mask size")
        assert(backgroundImage.size == self.size, "background image size is not equal to mask size")
        
        let fimage = foregroundImage.normalize()
        let bimage = backgroundImage.normalize()
        
        let width = Int(fimage.size.width)
        let height = Int(fimage.size.height)
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.draw(backgroundImage.cgImage!, in: CGRect(origin: CGPoint(), size: bimage.size))
        ctx.setBlendMode(.sourceAtop)
        ctx.draw(cutout(image: fimage, resize: false)!.cgImage!, in: CGRect(origin: CGPoint(), size: self.size))
        return UIImage(cgImage: ctx.makeImage()!)
    }
}
