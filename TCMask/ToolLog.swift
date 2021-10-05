//
//  ToolLog.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 10/12/16.
//
//

import Foundation

class ToolLog {
    let type: TCMaskTool
    var idx = -1
    
    var count: Int { return -1 }
    var size: Int { fatalError("should be overwrittene") }
    
    init(type: TCMaskTool) {
        self.type = type
    }
    
    func undo(tool: Tool) {
        fatalError("should be overwritten")
    }
    
    func redo(tool: Tool) {
        fatalError("should be overwritten")
    }
    
    func invert() {
        fatalError("should be overwritten")
    }
}
