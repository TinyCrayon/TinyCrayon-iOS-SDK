//
//  QuickSelectLog.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 10/12/16.
//
//

import Foundation
import TCCore

class QuickSelectLog : ToolLog {
    var diffs = [[UInt32]]()
    var encodedMask: [UInt32]!
    var encodedAlpha: [UInt32]!
    
    override var count: Int { return diffs.count }
    
    override var size: Int {
        var retval = 0
        for diff in diffs { retval += diff.count }
        return retval
    }
    
    init() {
        super.init(type: .quickSelect)
    }
    
    func push(diff: [UInt32]) {
        idx = idx + 1
        diffs.removeLast(diffs.count - idx)
        diffs.append(diff)
    }
    
    override func undo(tool: Tool) {
        assert(tool.type == self.type, "inv type: tool:\(tool.type) self:\(self.type)")
        let qstool = tool as! QuickSelectTool

        if qstool.isSelectRunning {
            return
        }
        
        let diff = diffs[idx]
        if diff.count == 0 {
            qstool.invert()
        }
        else {
            TCCore.logDecodeDiff(to: &qstool.mask, from: qstool.mask, diff: diff, count: qstool.mask.count, diffCount: diff.count)
            TCCore.arrayCopy(&qstool.previousMask, src: qstool.mask, count: qstool.mask.count)
        }
        idx -= 1
    }
    
    override func redo(tool: Tool) {
        assert(tool.type == self.type, "inv type: tool:\(tool.type) self:\(self.type)")
        let qstool = tool as! QuickSelectTool

        if qstool.isSelectRunning {
            return
        }
        
        idx += 1
        let diff = diffs[idx]
        if diff.count == 0 {
            qstool.invert()
        }
        else {
            TCCore.logDecodeDiff(to: &qstool.mask, from: qstool.mask, diff: diff, count: qstool.mask.count, diffCount: diff.count)
            TCCore.arrayCopy(&qstool.previousMask, src: qstool.mask, count: qstool.mask.count)
        }        
    }
    
    override func invert() {
        idx = idx + 1
        diffs.removeLast(diffs.count - idx)
        diffs.append([UInt32]())
    }
}
