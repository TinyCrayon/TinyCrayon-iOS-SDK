//
//  ImageScrollView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 1/4/16.
//
//

import UIKit

enum FitMode {
    case inner, outer
}

class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    var baseView: UIView
    var zoomFactor: CGFloat = 1
    var minScale: CGFloat = 1
    var fitMode = FitMode.inner
    
    var draggingDisabled = false
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer {
            if draggingDisabled && gesture.numberOfTouches == 1 {
                return false
            }
        }
        return true
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if (draggingDisabled) {
            targetContentOffset.pointee = scrollView.contentOffset
        }
    }
    
    weak var _zoomView: UIView?
    var zoomView: UIView? {
        willSet {
            _zoomView?.removeFromSuperview()
            if let view = newValue {
                baseView.addSubview(view)
            }
            _zoomView = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        baseView = UIView()
        super.init(coder: aDecoder)
        
        self.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        self.clipsToBounds = true
        self.bounces = true
        self.bouncesZoom = true
        self.delegate = self
        self.delaysContentTouches = true
        self.addSubview(baseView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return baseView
    }
    
    func refresh() {
        self.resetImageViewFrame()
        self.resetZoomScale(false, resetScale: true)
    }
    
    func resetImageViewFrame() -> (){
        if let view = _zoomView {
            view.frame.origin = CGPoint(x: 0, y: 0)
            baseView.bounds = view.bounds
        }
    }
    
    func resetZoomScale(_ animated: Bool, resetScale: Bool = false) -> (){
        if let view = _zoomView {
            let rw = self.width / view.width
            let rh = self.height / view.height

            if (self.fitMode == FitMode.inner) {
                self.minimumZoomScale = min(rw, rh)
                self.maximumZoomScale = max(max(rw, rh) * zoomFactor, self.minimumZoomScale)
            }
            else {
                self.minimumZoomScale = max(rw, rh)
                self.maximumZoomScale = self.minimumZoomScale * zoomFactor
            }
            
            if (resetScale) {
                self.contentSize = view.frame.size
                self.setZoomScale(minimumZoomScale, animated: animated)
            }
            else {
                self.setZoomScale(zoomScale, animated: animated)
            }
            scrollViewDidZoom(self)
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let ws = scrollView.width - scrollView.contentInset.left - scrollView.contentInset.right
        let hs = scrollView.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let w = baseView.width
        let h = baseView.height
        var rct = baseView.frame
        rct.origin.x = max((ws-w)/2, 0)
        rct.origin.y = max((hs-h)/2, 0)
        baseView.frame = rct
    }
}
