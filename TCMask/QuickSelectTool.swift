//
//  QuickSelectTool.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/22/16.
//
//

import Foundation
import UIKit
import TCCore

class QuickSelectTool : Tool {
    static let selectQueue = DispatchQueue(label: "select queue", attributes: [])
    
    var image: UIImage!
    var pendingPoints = [(p1: CGPoint, p2: CGPoint, lineWidth: CGFloat, param: ToolParams)]()
    var currentRect: CGRect!
    var isSelectRunning = false
    var hasPendingSelection = false
    
    var logLen: Int = 0
    var logOff: Int = 0
    var needToPushLog = false
    
    var mask = [UInt8]()
    var previousMask = [UInt8]()
    var undoLog = [UInt16]()
    
    init(maskView: MaskView, toolManager: ToolManager) {
        super.init(type: TCMaskTool.quickSelect, maskView: maskView, toolManager: toolManager)
        self.image = maskView.image

        // allocate memory space for mask
        self.mask = [UInt8](repeating: UInt8(GC_MASK_PR_BGD), count: maskView.opacity.count)
        TCCore.mask(fromAlpha: maskView.opacity, mask: &mask, size: image.size)
        
        // allocate memory space for previous mask using for undo-redo log
        self.previousMask = [UInt8](repeating: UInt8(GC_MASK_PR_BGD), count: maskView.opacity.count)
        TCCore.arrayCopy(&previousMask, src: mask, count: mask.count)
    }
    
    override func refresh() {        
        let redrawImage = TCCore.image(fromMask: self.mask, alpha: maskView.opacity, size: image.size, rect: CGRect(origin: CGPoint(), size: image.size))
        maskView.drawImgToCache(redrawImage!, rect: CGRect(origin: CGPoint(), size: image.size))
    }
    
    override func invert() {
        if (isSelectRunning) { return }
        
        TCCore.invertMask(&self.mask, count: self.mask.count)
        TCCore.invertAlpha(&maskView.opacity, count: maskView.opacity.count)
        TCCore.arrayCopy(&previousMask, src: mask, count: mask.count)
        refresh()
    }
    
    override func endProcessing() {
        TCCore.alpha(fromMask: mask, alpha: &maskView.opacity, size: image.size)
    }
    
    override func touchBegan(_ location: CGPoint) {
        if (!isSelectRunning) {
            notifyWillBeginProcessing()
        }
        
        let scrollView = maskView.scrollView!
        let scaleFactor = maskView.scaleFactor
        
                
        let rectSize = CGSize(
            width: min(scrollView.width, scrollView.contentSize.width),
            height: min(scrollView.height, scrollView.contentSize.height))
        let rectCenter = CGPoint(
            x: scrollView.contentOffset.x + rectSize.width/2,
            y: scrollView.contentOffset.y + rectSize.height/2)
        
        currentRect = CGRect(
            x: max(0, floor((rectCenter.x - rectSize.width) * scaleFactor / scrollView.zoomScale)),
            y: max(0, floor((rectCenter.y - rectSize.height) * scaleFactor / scrollView.zoomScale)),
            width: ceil(rectSize.width * 2 * scaleFactor / scrollView.zoomScale),
            height: ceil(rectSize.height * 2 * scaleFactor / scrollView.zoomScale))
        
        if (currentRect.origin.x + currentRect.width > image.size.width) {
            currentRect.size.width = image.size.width - currentRect.origin.x
        }
        if (currentRect.origin.y + currentRect.height > image.size.height) {
            currentRect.size.height = image.size.height - currentRect.origin.y;
        }
    }
    
    override func touchMoved(_ previousLocation: CGPoint, _ location: CGPoint) {
        drawLine(previousLocation: previousLocation, location: location)
        imageSelect()
    }
    
    override func touchEnded(_ previousLocation: CGPoint, _ location: CGPoint) {
        drawLine(previousLocation: previousLocation, location: location)
        imageSelect()

        if(isSelectRunning) {
            notifyIsWaitingForProcessing()
        }
        else {
            selectDidEnd()
        }
    }
    
    func drawLine(previousLocation: CGPoint, location: CGPoint) {
        let scaleFactor = maskView.scaleFactor
        let p2 = CGPoint(x: Int(location.x * scaleFactor), y: Int(location.y * scaleFactor))
        let p1 = CGPoint(x: Int(previousLocation.x * scaleFactor), y: Int(previousLocation.y * scaleFactor))
        let params = delegate.getToolParams()
        let lineWidth =  maskView.lineWidth(scribbleSize: CGFloat(params.quickSelectBrushSize))
        
        _ = maskView.drawLine(p1: p1, p2: p2, lineWidth: lineWidth, add: params.add)
        
        pendingPoints.append((p1, p2, lineWidth, params))
    }
    
    func selectDidEnd() {
        if self.needToPushLog {
            toolManager.pushLogOfQuickSelect(previousMask: previousMask, currentMask: mask)
            TCCore.arrayCopy(&previousMask, src: mask, count: mask.count)
            self.needToPushLog = false
        }
        
        notifyDidEndProcessing()
    }

    
    func imageSelect() {
        if (self.isSelectRunning) {
            self.hasPendingSelection = true
            return
        }
        
        self.isSelectRunning = true
        
        let segRect = currentRect
        let points = self.pendingPoints
        let toolParams = delegate.getToolParams()
        let segMode = toolParams.add ? GC_MODE_FGD : GC_MODE_BGD
        
        self.pendingPoints.removeAll()
        self.hasPendingSelection = false
        
        QuickSelectTool.selectQueue.async(execute: {
            var outRect = CGRect()
            var segImage: UIImage!
            var regionContext: CGContext!
            var activeRegion = [UInt8](repeating: UInt8(GC_UNINIT), count: self.mask.count)
            
            regionContext = CGContext(data: &activeRegion, width: Int(self.image.size.width), height: Int(self.image.size.height), bitsPerComponent: 8, bytesPerRow: Int(self.image.size.width), space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
            regionContext.setLineCap(CGLineCap.round)
            regionContext.setLineJoin(CGLineJoin.round)
            regionContext.setShouldAntialias(false)
            
            // CGContextDrawImage draws image upside down
            // http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
            regionContext.translateBy(x: 0, y: self.image.size.height)
            regionContext.scaleBy(x: 1.0, y: -1.0)
            
            for (p1, p2, lineWidth, params) in points {
                let colorValue = params.add ? GC_MASK_FGD : GC_MASK_BGD
                let regionColor = UIColor(red: 0, green: 0, blue: 0, alpha: (CGFloat(colorValue) / 255.0))
                _ = CGContextDrawLine(regionContext, p1: p1, p2: p2, lineWidth: lineWidth, color: regionColor.cgColor)
            }

            assert(segRect != nil)
            
            if (TCCore.imageSelect(self.maskView.imageData, size:self.image.size, mask: &self.mask, region: activeRegion, opacity: &self.maskView.opacity, mode: Int(segMode), edgeDetection:true, rect: segRect!, outRect: &outRect)){
                segImage = TCCore.image(fromMask: self.mask, alpha:self.maskView.opacity, size: self.image.size, rect: outRect)
                self.needToPushLog = true
            }
            else {
                watch.abort()
            }
            
            DispatchQueue.main.async(execute: {
                self.isSelectRunning = false

                // draw segmentation result
                if let img = segImage {
                    self.maskView.drawImgToCache(img, rect: outRect)
                }
                
                // draw pending points
                for (p1, p2, lineWidth, params) in self.pendingPoints {
                    _ = self.maskView.drawLine(p1: p1, p2: p2, lineWidth: lineWidth, add: params.add)
                }
                
                // release memory
                segImage = nil
                activeRegion = []
                regionContext = nil
                
                if (self.hasPendingSelection) {
                    self.imageSelect()
                }
                else if (self.maskView.touchEnded) {
                    self.selectDidEnd()
                }
            })
        })
    }
}
