//
//  HairBrushTool.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/22/16.
//
//

import UIKit
import TCCore

class HairBrushTool : Tool {
    var imgSize: CGSize!
    
    var canvasView: CanvasView!
    var regionRect = CGRect()
    var previousAlpha = [UInt8]()
    var activeRegion = [UInt8]()
    var regionContext: CGContext!
    var sessionPoints = [(CGPoint, CGPoint, CGFloat)]()
    
    init(maskView: MaskView, toolManager: ToolManager) {
        super.init(type: TCMaskTool.hairBrush, maskView: maskView, toolManager: toolManager)
        self.imgSize = maskView.image.size

        previousAlpha = [UInt8](repeating: 0, count: maskView.opacity.count)
        TCOpenCV.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
        
        activeRegion = [UInt8](repeating: UInt8(GM_UNINIT), count: maskView.opacity.count)
        regionContext = CGContext(data: &activeRegion, width: Int(imgSize.width), height: Int(imgSize.height), bitsPerComponent: 8, bytesPerRow: Int(imgSize.width), space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
        regionContext.setLineCap(CGLineCap.round)
        regionContext.setLineJoin(CGLineJoin.round)
        regionContext.setShouldAntialias(false)
        
        // CGContextDrawImage draws image upside down
        // http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
        regionContext.translateBy(x: 0, y: imgSize.height)
        regionContext.scaleBy(x: 1.0, y: -1.0)
    }
    
    override func refresh() {
        maskView.refresh()
    }
    
    override func invert() {
        TCOpenCV.invertAlpha(&maskView.opacity, count: maskView.opacity.count)
        TCOpenCV.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
        refresh()
    }
    
    override func touchBegan(_ location: CGPoint) {
        notifyWillBeginProcessing()
    }
    
    override func touchMoved(_ previousLocation: CGPoint, _ location: CGPoint) {
        let scaleFactor = maskView.scaleFactor
        let scrollView = maskView.scrollView!
        let params = delegate.getToolParams()
        
        let p1 = previousLocation * scaleFactor
        let p2 = location * scaleFactor
        
        let lineWidth = min(60, CGFloat(params.hairBrushBrushSize) * scaleFactor / scrollView.zoomScale)
        let color = UIColor(white: 0, alpha: CGFloat(GM_UNKNOWN) / 255.0)
        let rect = CGContextDrawLine(regionContext, p1: p1, p2: p2, lineWidth: lineWidth, color: color.cgColor)
        let paintColor = UIColor(white: 0, alpha: CGFloat(params.add ? GM_FGD : GM_BGD) / 255.0)
        _ = CGContextDrawLine(regionContext, p1: p1, p2: p2, lineWidth: lineWidth / 2, color: paintColor.cgColor)
        
        if (TCOpenCV.imageFiltering(self.maskView.imageData, size: imgSize, alpha: &maskView.opacity, region: activeRegion, rect: rect, add: params.add)) {
            let mattingImage = TCOpenCV.image(fromAlpha: maskView.opacity, size: imgSize, rect: rect)!
            maskView.drawImgToCache(mattingImage, rect: rect)
            sessionPoints.append((p1, p2, lineWidth))
        }
        let uninitColor = UIColor(white: 0, alpha: CGFloat(GM_UNINIT) / 255.0)
        CGContextFillRect(regionContext, rect: rect, color: uninitColor.cgColor)
    }
    
    override func touchEnded(_ previousLocation: CGPoint, _ location: CGPoint) {
        self.sessionPoints.removeAll()
        self.notifyDidEndProcessing()
    }
    
    override func notifyDidEndProcessing() {
        toolManager.pushLogOfHairBrush(previousAlpha: previousAlpha, currentAlpha: maskView.opacity)
        TCOpenCV.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
        super.notifyDidEndProcessing()
    }
}
