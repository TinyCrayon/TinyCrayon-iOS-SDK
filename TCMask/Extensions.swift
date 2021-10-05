//
//  Extensions.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 9/24/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

import UIKit

func *(rect: CGRect, scale: CGFloat) -> CGRect {
    return CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
}

func /(rect: CGRect, scale: CGFloat) -> CGRect {
    return rect * (1/scale)
}

func *(size: CGSize, scale: CGFloat) -> CGSize {
    return CGSize(width: size.width * scale, height: size.height * scale)
}

func /(size: CGSize, scale: CGFloat) -> CGSize {
    return size * (1/scale)
}

func *(point: CGPoint, scale: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scale, y: point.y * scale)
}

func /(point: CGPoint, scale: CGFloat) -> CGPoint {
    return point * (1/scale)
}

func +(point1: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPoint(x: point1.x + point2.x, y: point1.y + point2.y)
}

func -(point1: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
}

extension Array {
    func indexOf<T: AnyObject>(_ obj: T) -> Int {
        for i in 0..<self.count {
            if obj === (self[i] as! T){
                return i
            }
        }
        return -1
    }
}

extension CGRect {
    var centerX: CGFloat {
        get { return origin.x + size.width / 2 }
        set { self.origin.x =  newValue - size.width / 2 }
    }
    
    var centerY: CGFloat {
        get { return origin.y + size.height / 2 }
        set { self.origin.y =  newValue - size.height / 2 }
    }
    
    var center: CGPoint {
        get { return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2) }
        set { self.origin = CGPoint(x: newValue.x - size.width / 2, y:newValue.y - size.height / 2) }
    }
    
    var left: CGFloat {
        get { return self.origin.x }
        set { self.origin.x = newValue }
    }
    
    var top: CGFloat {
        get { return self.origin.y }
        set { self.origin.y = newValue }
    }
    
    var right: CGFloat {
        get { return self.origin.x + self.size.width }
        set { self.origin.x = newValue - self.size.width }
    }
    
    var bottom: CGFloat {
        get { return self.origin.y + self.size.height }
        set { self.origin.y = newValue - self.size.height }
    }
}

extension UIView {
    var top: CGFloat {
        get { return self.frame.origin.y }
        set { self.frame.origin.y = newValue }
    }
    var right: CGFloat {
        get { return self.frame.origin.x + self.frame.size.width }
        set { self.frame.origin.x = newValue - self.frame.size.width }
    }
    var bottom: CGFloat {
        get { return self.frame.origin.y + self.frame.size.height }
        set { self.frame.origin.y = newValue - self.frame.size.height }
    }
    var left: CGFloat {
        get { return self.frame.origin.x }
        set { self.frame.origin.x = newValue }
    }
    var width: CGFloat {
        get { return self.frame.size.width }
        set { self.frame.size.width = newValue }
    }
    var height: CGFloat {
        get { return self.frame.size.height }
        set { self.frame.size.height = newValue }
    }
    
    func clearGestureRecognizers(){
        if let recognizers = self.gestureRecognizers {
            for recognizer in recognizers {
                self.removeGestureRecognizer(recognizer )
            }
        }
    }
    
    func allSubviews() -> [UIView] {
        var queue = self.subviews
        var idx = 0
        
        while idx < queue.count {
            queue += queue[idx].subviews
            idx += 1
        }
        
        return queue
    }
}

extension UIImage {
    static func from(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    func isIndexedColorSpace() -> Bool {
        let imageRef = self.cgImage
        let colorSpace = imageRef?.colorSpace

        return colorSpace!.colorTable!.count > 0
    }
    
    func resize(_ size: CGSize) -> UIImage {
        // round size to integer
        var ctx: CGContext?
        ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
            bitsPerComponent: (self.cgImage?.bitsPerComponent)!, bytesPerRow: 0,
            space: (self.cgImage?.colorSpace!)!,
            bitmapInfo: (self.cgImage?.alphaInfo.rawValue)!);
        if (ctx == nil) {
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo().rawValue | CGImageAlphaInfo.noneSkipLast.rawValue)
            // For some PNG format redraw image to a regular format so that it can be easily processed by openCV
            ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                bitsPerComponent: 8, bytesPerRow: Int(4 * self.size.width), space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue)!;
        }
        ctx!.interpolationQuality = CGInterpolationQuality.high
        
        ctx?.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
        let image = UIImage(cgImage: (ctx?.makeImage()!)!)
        return image;
    }
    
    func imageWithFixedOrientation() -> UIImage {        
        guard let cgImage = self.cgImage else {
            return self
        }
        
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        let width  = self.size.width
        let height = self.size.height
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat.pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5*CGFloat.pi)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5*CGFloat.pi)
            
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let colorSpace = cgImage.colorSpace else {
            return self
        }
        
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: UInt32(cgImage.bitmapInfo.rawValue))
        else {
            return self
        }
        
        context.concatenate(transform);
        
        switch self.imageOrientation {
            
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
            
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let newCGImg = context.makeImage() else {
            return self
        }
        
        let img = UIImage(cgImage: newCGImg)
        
        return img;
    }
    
    func normalize() -> UIImage {
        if (self.cgImage == nil && self.ciImage != nil) {
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(self.ciImage!, from: self.ciImage!.extent)
            return UIImage(cgImage: cgImage!)
        }
        
        let image = self.imageWithFixedOrientation()
        assert(image.cgImage != nil)
        let cg = image.cgImage!
        
        let paramsList: [(Int, Int, CGImageAlphaInfo)] = [(16, 5, .noneSkipFirst), (32, 8, .noneSkipFirst), (32, 8, .noneSkipLast), (32, 8, .premultipliedFirst), (32, 8, .premultipliedLast), (64, 16, .premultipliedLast), (64, 16, .noneSkipLast)]
        for (bitsPerPixel, bitsPerComponent, alphainfo) in paramsList {
            if (cg.bitsPerPixel == bitsPerPixel && cg.bitsPerComponent == bitsPerComponent && cg.alphaInfo == alphainfo) {
                return image
            }
        }
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(4 * size.width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = CGInterpolationQuality.default
        let destRect = CGRect(origin: CGPoint(), size: image.size)
        context.draw(image.cgImage!, in: destRect)
        let cgimage = context.makeImage()!
        return UIImage(cgImage: cgimage)
    }
}

extension UIFont {
    
    func withTraits(_ traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
    
    func bold() -> UIFont {
        return withTraits(.traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(.traitItalic)
    }
    
    func boldItalic() -> UIFont {
        return withTraits(.traitBold, .traitItalic)
    }
}

extension UIColor {
    static func pngColor(_ scale: Int = 20) -> UIColor {
        let size = max(scale, 1)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.setFillColor(UIColor(white: (233.0/255.0), alpha: 1).cgColor)
        context.fill(CGRect(x: size/2, y: 0, width: size/2, height: size/2))
        context.fill(CGRect(x: 0, y: size/2, width: size/2, height: size/2))
        let image = context.makeImage()
        return UIColor(patternImage: UIImage(cgImage: image!))
    }
    
    static func tint() -> UIColor {
        return UIColor(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
    }
    
    
    func rgba() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
             return (red:fRed, green:fGreen, blue:fBlue, alpha:fAlpha)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

extension UIDevice {
    var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

class Unowned<T: AnyObject> {
    unowned var value : T
    init (_ value: T) {
        self.value = value
    }
}
