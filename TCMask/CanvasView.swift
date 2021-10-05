//
//  CanvasView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 2/16/16.
//
//

import UIKit

class CanvasView : UIView {
    let scaleFactor = UIScreen.main.scale
    var cacheContext: CGContext!
    var _data = [UInt8]()
    var data: [UInt8] { get {return _data} }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initCacheContext()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initCacheContext()
    }
    
    // http://www.effectiveui.com/blog/2011/12/02/how-to-build-a-simple-painting-app-for-ios/
    // How to build a Simple Painting App for iOS
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setBlendMode(CGBlendMode.copy)

        // Draw cache image to ctx
        let width = CGFloat(cacheContext.width)
        let height = CGFloat(cacheContext.height)
        let scaleX = width / self.bounds.size.width
        let scaleY = height / self.bounds.size.height
        
        let scaledRect = CGRect(x: round(rect.origin.x * scaleX), y: round(height - rect.origin.y * scaleY - rect.size.height * scaleY), width: round(rect.size.width * scaleX), height: round(rect.size.height * scaleY))
        let cacheImage = cacheContext.makeImage()!.cropping(to: scaledRect)
            ctx.draw(cacheImage!, in: rect)
    }
    
    func initCacheContext() {
        let width = Int(round(self.width * scaleFactor))
        let height = Int(round(self.height * scaleFactor))
        self._data = [UInt8](repeating: 0, count: width * height * 4)
        self.cacheContext = CGContext(data: &_data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        cacheContext.setLineCap(CGLineCap.round)
        cacheContext.setLineJoin(CGLineJoin.round)
        cacheContext.setShouldAntialias(false)
    }
    
    deinit {
    }
}
