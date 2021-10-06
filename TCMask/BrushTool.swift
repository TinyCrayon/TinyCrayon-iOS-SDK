//
//  RegularBrushTool
//  TinyCrayon
//
//  Created by Xin Zeng on 6/22/16.
//
//

import UIKit
import TCCore

class BrushTool : Tool {
    var imgSize: CGSize!
    var previousAlpha = [UInt8]()
    var previousPoint = CGPoint()

    init(maskView: MaskView, toolManager: ToolManager) {
        super.init(type: .brush, maskView: maskView, toolManager: toolManager)
        
        imgSize = maskView.image.size
        
        previousAlpha = [UInt8](repeating: 0, count: maskView.opacity.count)
        TCCore.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
    }
    
    override func refresh() {
        maskView.refresh()
    }
    
    override func invert() {
        TCCore.invertAlpha(&maskView.opacity, count: maskView.opacity.count)
        TCCore.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
        refresh()
    }
    
    override func endProcessing() {
    }
    
    override func touchBegan(_ location: CGPoint) {
        notifyWillBeginProcessing()
        drawCircularGrident(center: location)
        previousPoint = location;
    }
    
    override func touchMoved(_ previousLocation: CGPoint, _ location: CGPoint) {
        if (round(previousLocation.x * maskView.scaleFactor) == round(location.x * maskView.scaleFactor) && round(previousLocation.y * maskView.scaleFactor) == round(location.y * maskView.scaleFactor)) {
            return
        }
        drawCircularGrident(center: location)
    }
    
    override func touchEnded(_ previousLocation: CGPoint, _ location: CGPoint) {
        toolManager.pushLogOfBrush(previousAlpha: previousAlpha, currentAlpha: maskView.opacity)
        TCCore.arrayCopy(&previousAlpha, src: maskView.opacity, count: previousAlpha.count)
        notifyDidEndProcessing()
    }
    
    func drawCircularGrident(center: CGPoint) {
        let params = delegate.getToolParams()
        let endRadius = maskView.lineWidth(scribbleSize: params.brushSize)  / 2
        let startRadius = endRadius * params.brushHardness
        var outRect = CGRect()
        if (TCCore.drawRadialGradient(onAlpha: &maskView.opacity, size: imgSize, center: center * maskView.scaleFactor, startValue: UInt8(params.brushOpacity * params.brushOpacity * 255), startRadius: startRadius, endValue: 0, endRadius: endRadius, outRect: &outRect, add: params.add))
        {
            maskView.refresh(outRect)
        }
    }
}
