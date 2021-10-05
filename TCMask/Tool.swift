//
//  Tool.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/23/16.
//
//

import UIKit

protocol ToolDelegate : AnyObject {
    func toolWillBeginProcessing(_ tool: Tool)
    func toolDidEndProcessing(_ tool: Tool)
    func toolIsWaitingForProcessing(_ tool: Tool)
    func getToolParams() -> ToolParams
}

class Tool : NSObject, UITabBarDelegate {
    weak var maskView: MaskView!
    weak var delegate: ToolDelegate!
    weak var toolManager: ToolManager!

    let type: TCMaskTool
    
    init(type: TCMaskTool, maskView: MaskView, toolManager: ToolManager) {
        self.type = type
        self.maskView = maskView
        self.toolManager = toolManager
        super.init()
    }
    
    deinit {
    }
    
    func refresh() {
        fatalError("Should be overwritten by subclass")
    }
    
    func invert() {
        fatalError("Should be overwritten by subclass")
    }
    
    func endProcessing() {
        
    }
    
    func touchBegan(_ location: CGPoint) {
    
    }
    
    func touchMoved(_ previousLocation: CGPoint, _ location: CGPoint) {
    
    }
    
    func touchEnded(_ previousLocation: CGPoint, _ location: CGPoint) {
    
    }
    
    func notifyWillBeginProcessing() {
        delegate!.toolWillBeginProcessing(self)
    }
    
    func notifyIsWaitingForProcessing() {
        delegate!.toolIsWaitingForProcessing(self)
    }
    
    func notifyDidEndProcessing() {
        delegate!.toolDidEndProcessing(self)
    }
}
