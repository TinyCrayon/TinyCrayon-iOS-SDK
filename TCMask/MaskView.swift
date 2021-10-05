//
//  MaskView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 10/31/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

import UIKit
import TCCore

protocol MaskViewDelegate : AnyObject {
    func maskViewTouchBegan(_ maskView: MaskView, _ location: CGPoint)
    func maskViewTouchMoved(_ maskView: MaskView, _ previousLocation: CGPoint, _ location: CGPoint)
    func maskViewTouchEnded(_ maskView: MaskView, _ previousLocation: CGPoint, _ location: CGPoint)
}

class MaskView : UIView {
    // MARK: - variables
    let scaleFactor = UIScreen.main.scale
    var opacity = [UInt8]()
    var image: UIImage!
    var imageData = [UInt8]()
    var imageView: UIImageView!
    var canvasView: CanvasView!
    var foregroundColor = UIColor.clear
    var shouldForceSelect = true
    
    var inverted = false

    weak var delegate: MaskViewDelegate!
    weak var scrollView: UIScrollView! {
        didSet {
            let panGesture = UIPanGestureRecognizer()
            panGesture.addTarget(self, action: #selector(self.handlePenGesture(_:)))
            panGesture.maximumNumberOfTouches = 1
            panGesture.minimumNumberOfTouches = 1
            self.scrollView.addGestureRecognizer(panGesture)
        }
    }
    
    var previousLocation: CGPoint!
    var touchEnded : Bool {
        get { return previousLocation == nil }
    }

    
    var scale: CGFloat {
        get { return self.scrollView.zoomScale / self.scrollView.minimumZoomScale }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        self.isOpaque = true
        self.backgroundColor = UIColor.clear
    }
    
    deinit {
    }
    
    func setViewMode(_ viewMode: TCMaskViewMode) {
        if (viewMode.backgroundColor == nil && viewMode.backgroundImage == nil) {
            viewMode.backgroundImage = self.image
        }
        
        if (viewMode.foregroundColor == nil && viewMode.foregroundImage == nil) {
            let scale = Int(min(image.size.width, image.size.height) / 16)
            viewMode.foregroundColor = UIColor.pngColor(scale)
        }
        
        if viewMode.backgroundImage != nil {
            imageView.image = viewMode.backgroundImage
            imageView.backgroundColor = UIColor.clear
        }
        else {
            imageView.image = nil
            imageView.backgroundColor = viewMode.backgroundColor
        }
        
        if viewMode.foregroundImage != nil {
            foregroundColor = UIColor(patternImage: viewMode.foregroundImage.resize(image.size))
        }
        else {
            foregroundColor = viewMode.foregroundColor
        }
        
        self.inverted = viewMode.isInverted
    }
    
    func drawLine(p1: CGPoint, p2: CGPoint, lineWidth: CGFloat, add: Bool) -> CGRect {
        var cacheColor: UIColor
        if ((add && !inverted) || (!add && inverted)) {
            cacheColor = foregroundColor
        }
        else {
            cacheColor = UIColor.clear
        }
        
        let rect = CGContextDrawLine(canvasView.cacheContext, p1: p1, p2: p2, lineWidth: lineWidth, color: cacheColor.cgColor) / scaleFactor
        
        canvasView.setNeedsDisplay(rect)
        return rect
    }
    
    func drawImgToCache(_ image: UIImage, rect: CGRect) {
        canvasView.cacheContext.setFillColor(foregroundColor.cgColor)
        canvasView.cacheContext.setBlendMode(CGBlendMode.copy)
        canvasView.cacheContext.fill(rect)

        let blendMode = inverted ? CGBlendMode.destinationOut : CGBlendMode.destinationIn

        CGContextDrawImage(canvasView.cacheContext, image: image, rect: rect, blendMode: blendMode)
        
        canvasView.setNeedsDisplay(rect / scaleFactor)
    }

    func loadImage(_ img: UIImage, viewMode: TCMaskViewMode, initOpacity: UInt8) {
        self.image = img
        
        // allocate memory space for opacity
        self.opacity = [UInt8](repeating: initOpacity, count: Int(image.size.width * image.size.height))

        // init image data
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        imageData = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext (data: &imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setShouldAntialias(false)
        ctx.draw(image.cgImage!, in: CGRect(origin: CGPoint(), size: image.size))
        
        // init image view
        self.imageView = UIImageView(frame: self.bounds)
        self.addSubview(imageView)
        
        // init canvas view
        self.canvasView = CanvasView(frame: self.bounds)
        canvasView.backgroundColor = UIColor.clear
        canvasView.isUserInteractionEnabled = false
        
        self.addSubview(canvasView)
        
        self.setViewMode(viewMode)
    }
    
    @objc func handlePenGesture(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self)
        
        switch sender.state {
        case .began:
            delegate?.maskViewTouchBegan(self, location)
            assert(previousLocation == nil)
            previousLocation = location
        case .changed:
            delegate?.maskViewTouchMoved(self, previousLocation, location)
            assert(previousLocation != nil)
            previousLocation = location
        default:
            delegate?.maskViewTouchEnded(self, previousLocation, previousLocation)
            assert(previousLocation != nil)
            previousLocation = nil
        }
    }
    
    func refresh(_ rect: CGRect) {
        let r = CGRect(x: max(rect.origin.x, 0), y: max(rect.origin.y, 0), width: min(rect.size.width, image.size.width), height: min(rect.size.height, image.size.height))
        let redrawImage = TCOpenCV.image(fromAlpha: self.opacity, size: self.image.size, rect: r)
        drawImgToCache(redrawImage!, rect: r)
    }
    
    func refresh() {
        self.refresh(CGRect(origin: CGPoint(), size: image.size))
    }
    
    // MARK: - output
    func getAlpha(_ size: CGSize) -> [UInt8] {
        var retval = [UInt8](repeating: 0, count: Int(size.width * size.height))
        TCOpenCV.arrayResize(&retval, src: self.opacity, dstSize: size, srcSize: size)
        return retval
    }
    
    func canPerformNext() -> Bool {
        if (!shouldForceSelect) {
            return true
        }
        return !TCOpenCV.arrayCheckAll(opacity, value: 0, count: opacity.count)
    }
    
    func lineWidth(scribbleSize: CGFloat) -> CGFloat {
        return scribbleSize / scrollView.zoomScale * scaleFactor
    }
    
    func resizedOpacity(size: CGSize) -> [UInt8] {
        var retval = [UInt8](repeating: 0, count: Int(size.width * size.height))
        TCOpenCV.arrayResize(&retval, src: self.opacity, dstSize: size, srcSize: image.size)
        return retval
    }
}
