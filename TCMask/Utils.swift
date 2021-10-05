//
//  Utils.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 11/1/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

import UIKit

let watch = StopWatch()

class StopWatch {
    var times = [Date]()
    
    func begin() {
        self.times.append(Date())
    }
    
    func end(_ msg: String) {
        let start = self.times.removeLast()
        let end = Date()
        let interval = end.timeIntervalSince(start)
        print("\(msg) - time:\(interval)s")
    }
    
    func abort() {
        self.times.removeLast()
    }
}

class Util {
    static func openAppStoreForReview(_ appleId: Int, completion: ((_ success: Bool) -> ())?) {
        let url  = URL(string: "itms-apps://itunes.apple.com/app/bars/id\(appleId)")
        if #available(iOS 10.0, *), UIApplication.shared.canOpenURL(url!) {
            DispatchQueue.main.async(execute: {
                UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                completion?(true)
            })
        }
        else {
            let errorAlert = UIAlertController(title: "Error Message", message: "An error happened when launching your App Store, please check your settings, or contact us via admin@tinycrayon.com", preferredStyle: UIAlertController.Style.alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                action -> () in
            }))
            let controller = UIApplication.shared.keyWindow!.rootViewController!
            controller.present(errorAlert, animated: true, completion: nil)
            completion?(false)
        }
    }
    
    static func getBufferAddress<T>(_ array: [T]) -> String {
        return array.withUnsafeBufferPointer { buffer in
            return String(describing: buffer.baseAddress)
        }
    }
    
    static func runBlockWithIndicatorInView(_ view: UIView, block: @escaping ()->(), completion: (() -> Void)! = nil) {
        let activityView = UIView(frame: view.bounds)
        let box = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        let indicator = UIActivityIndicatorView(frame: box.bounds)
        activityView.addSubview(box)
        
        view.addSubview(activityView)
        
        activityView.backgroundColor = UIColor(white: 0, alpha: 0)
        box.backgroundColor = UIColor(white: 0, alpha: 0.75)
        box.layer.cornerRadius = 10
        box.center = activityView.center
        box.addSubview(indicator)
        
        indicator.center = CGPoint(x: box.width / 2, y: box.height / 2)
        indicator.startAnimating()
        
        activityView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: {
            activityView.alpha = 1
        })
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(USEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
            block()
            UIView.animate(withDuration: 0.5, animations:
                {
                    activityView.alpha = 0
                }, completion:
                {
                    success in
                    completion?()
                    activityView.removeFromSuperview()
                }
            )
        })
    }
    
    static func printArray(_ arr: [UInt8]) {
        var dict = [UInt8:Int]()
        
        for e in arr {
            if let count = dict[e] {
                dict[e] = count + 1
            }
            else {
                dict[e] = 1
            }
        }
        
        let sortedDict = dict.sorted(by: { $0.0 < $1.0 })
        
        for (e, count) in sortedDict {
            print("\(e) : \(count)")
        }
    }
}

func CGContextDrawImageNoFlip(_ ctx: CGContext, _ rect: CGRect, _ image: CGImage?) {
    let height = CGFloat(ctx.height)
    ctx.draw(image!, in: CGRect(x: rect.origin.x, y: height - rect.origin.y - rect.height, width: rect.width, height: rect.height))
}

func CGContextDrawLine(_ ctx: CGContext, p1: CGPoint, p2: CGPoint, lineWidth: CGFloat, color: CGColor) -> CGRect {
    ctx.setStrokeColor(color)
    ctx.setBlendMode(CGBlendMode.copy)
    ctx.setLineWidth(lineWidth)
    ctx.move(to: CGPoint(x: p1.x, y: p1.y))
    ctx.addLine(to: CGPoint(x: p2.x, y: p2.y))
    ctx.strokePath()
    
    let width = CGFloat(ctx.width)
    let height = CGFloat(ctx.height)
    
    let dirtyPoint1 = CGRect(x: p1.x-lineWidth/2, y: p1.y-lineWidth/2, width: lineWidth, height: lineWidth)
    let dirtyPoint2 = CGRect(x: p2.x-lineWidth/2, y: p2.y-lineWidth/2, width: lineWidth, height: lineWidth)
    var scaledRect = dirtyPoint1.union(dirtyPoint2)
    scaledRect.origin.x = min(max(0, floor(scaledRect.origin.x)), width)
    scaledRect.origin.y = min(max(0, floor(scaledRect.origin.y)), height)
    scaledRect.size.width = min(width - scaledRect.origin.x, ceil(scaledRect.size.width))
    scaledRect.size.height = min(height - scaledRect.origin.y, ceil(scaledRect.size.height))
    
    return scaledRect
}

func CGContextFillRect(_ ctx: CGContext, rect: CGRect, color: CGColor) {
    ctx.setFillColor(color)
    ctx.setBlendMode(CGBlendMode.copy)
    ctx.fill(rect)
}

func CGContextDrawImage(_ ctx: CGContext, image: UIImage, rect: CGRect, blendMode: CGBlendMode) {
    UIGraphicsPushContext(ctx)
    image.draw(in: rect, blendMode: blendMode, alpha: 1)
    UIGraphicsPopContext()
}

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        Swift.print(items[0], separator:separator, terminator: terminator)
    #endif
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
