//
//  UILockableView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/19/16.
//
//

import UIKit

class UILockableView : UIView {
    var protectionCounter = 0
    var protected: Bool { get { return protectionCounter > 0 } }
    
    func enableProtection() {
        protectionCounter += 1
    }
    
    func disableProtection() {
        #if DEBUG
            assert(protectionCounter > 0)
        #endif
        protectionCounter -= 1
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var retval : UIView!
        if protected {
            self.disableProtection()
            retval = super.hitTest(point, with: event)
            self.enableProtection()
        }
        else {
            retval = super.hitTest(point, with: event)
        }
        return retval
    }

    override func layoutSublayers(of layer: CALayer) {
        if protected {
            self.disableProtection()
            super.layoutSublayers(of: layer)
            self.enableProtection()
        }
        else {
            super.layoutSublayers(of: layer)
        }
    }
    
    override var subviews: [UIView] {
        get {
            if protected {
                return []
            }
            return super.subviews
        }
    }
    
    override func addSubview(_ view: UIView) {
        if protected {
            #if DEBUG
                assert(false, "addSubview: view is locked")
            #else
                return
            #endif
        }
        super.addSubview(view)
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        if protected {
            #if DEBUG
                assert(false, "insertSubview: view is locked")
            #else
                return
            #endif
        }
        super.insertSubview(view, at: index)
    }
}
