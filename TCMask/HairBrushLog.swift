//
//  HairBrushLog.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 10/12/16.
//
//

import Foundation
import TCCore

class HairBrushLog : ToolLog {
    var diffs = [[UInt32]]()
    
    override var count: Int { return diffs.count }
    override var size: Int {
        var retval = 0
        for diff in diffs { retval += diff.count }
        return retval
    }
    
    init() {
        super.init(type: .hairBrush)
    }
    
    func push(diff: [UInt32]) {
        idx = idx + 1
        diffs.removeLast(diffs.count - idx)
        diffs.append(diff)
    }
    
    override func undo(tool: Tool) {
        assert(tool.type == self.type, "inv type: tool:\(tool.type) self:\(self.type)")
        let hbtool = tool as! HairBrushTool
        let diff = diffs[idx]

        if diff.count == 0 {
            hbtool.invert()
        }
        else {
            TCOpenCV.logDecodeDiff(to: &hbtool.maskView.opacity, from: hbtool.maskView.opacity, diff: diff, count: hbtool.maskView.opacity.count, diffCount: diff.count)
            TCOpenCV.arrayCopy(&hbtool.previousAlpha, src: hbtool.maskView.opacity, count: hbtool.previousAlpha.count)
        }
        
        idx -= 1
    }
    
    override func redo(tool: Tool) {
        assert(tool.type == self.type, "inv type: tool:\(tool.type) self:\(self.type)")
        let hbtool = tool as! HairBrushTool

        idx += 1
        let diff = diffs[idx]
        
        if diff.count == 0 {
            hbtool.invert()
        }
        else {
            TCOpenCV.logDecodeDiff(to: &hbtool.maskView.opacity, from: hbtool.maskView.opacity, diff: diff, count: hbtool.maskView.opacity.count, diffCount: diff.count)
            TCOpenCV.arrayCopy(&hbtool.previousAlpha, src: hbtool.maskView.opacity, count: hbtool.previousAlpha.count)
        }
    }
    
    override func invert() {
        idx = idx + 1
        diffs.removeLast(diffs.count - idx)
        diffs.append([UInt32]())
    }
}
