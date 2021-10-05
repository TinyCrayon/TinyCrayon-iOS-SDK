//
//  CircleView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 5/9/16.
//
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class CircleView : UIView {
    var color: UIColor = UIColor(white: 1, alpha: 0.5) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var size: CGFloat = 80 {
        didSet {
            self.frame.size = CGSize(width: size, height: size)
            self.setNeedsDisplay()
        }
    }
    
    var stroke: Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var hardness: CGFloat = 1 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setBlendMode(CGBlendMode.copy)
        
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(self.bounds)
        
        if (!self.stroke && self.hardness != 1) {
            let (r, g, b, _) = color.rgba()!
            let colorComponents = [r, g, b, 1, r, g, b, 0]
            let locations: [CGFloat] = [0, 1]
            let gradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(), colorComponents: colorComponents, locations: locations, count: 2)!
            let center = CGPoint(x: self.width / 2, y: self.height / 2)
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: self.size / 2 * self.hardness, endCenter: center, endRadius: self.size / 2, options: CGGradientDrawingOptions.drawsBeforeStartLocation)
        }
        else {
            ctx.setFillColor(self.color.cgColor)
            ctx.fillEllipse(in: self.bounds)
        }

        let strokeWidth: CGFloat = size / 16
        if (self.stroke && self.size > strokeWidth * 2) {
            ctx.setFillColor(UIColor.clear.cgColor)
            ctx.fillEllipse(in: CGRect(x: strokeWidth, y: strokeWidth, width: self.size - 2 * strokeWidth, height: self.size - 2 * strokeWidth))
        }
    }
}
