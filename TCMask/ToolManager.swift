//
//  ToolManager.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 10/3/16.
//
//

import Foundation
import TCCore

class ToolManager {
    
    weak var maskView: MaskView!
    weak var toolDelegate: ToolDelegate!
    
    let logSizeThreshold = 1024 * 1024 * 32
    
    var tool: Tool!
    
    // Buffer used for encoding and decoding
    var buf = [uint](repeating: 0, count: 1024 * 16)
    
    // Redo & Undo logs
    var logs = [ToolLog]()
    var logIdx = -1
    var logSize = 0
    
    deinit {
    }
    
    // Encode the difference between 'from' and 'to'
    func encodeDiff(from: [UInt8], to: [UInt8]) -> [UInt32] {
        var processed: Int32 = 0;
        var offset: Int32 = 0;
        var diff = [UInt32]()
        var completed = false
        
        while !completed {
            completed = TCCore.logEncodeDiff(from: from, to: to, count: to.count, buf: &buf, bufLen: Int32(buf.count), processed: &processed, offset: &offset)
            diff.append(contentsOf: buf[0..<Int(processed)])
        }
        
        return diff
    }
    
    // Encode array
    func encodeArray(array: [UInt8]) -> [UInt32] {
        var processed: Int32 = 0;
        var offset: Int32 = 0;
        var encoded = [UInt32]()
        var completed = false
        
        while !completed {
            completed = TCCore.logEncodeArray(array, count: array.count, buf: &buf, bufLen: Int32(buf.count), processed: &processed, offset: &offset)
            encoded.append(contentsOf: buf[0..<Int(processed)])
        }
        
        return encoded
    }
    
    func pushLogOfQuickSelect(previousMask: [UInt8], currentMask: [UInt8]) {
        var log: QuickSelectLog
        let diff = encodeDiff(from: previousMask, to: currentMask)
        
        // If diff have no change at all, just return
        if (!ToolManager.diffContainsChange(diff: diff)) {
            return
        }
        
        self.compactLog()

        if (logIdx >= 0 && logs[logIdx].type == .quickSelect) {
            log = logs[logIdx] as! QuickSelectLog
        }
        else {
            log = QuickSelectLog()
            appendLog(log: log)
        }
        
        log.push(diff: diff)
    }
    
    func pushLogOfHairBrush(previousAlpha: [UInt8], currentAlpha: [UInt8]) {
        var log: HairBrushLog
        let diff = encodeDiff(from: previousAlpha, to: currentAlpha)
        
        // If diff have no change at all, just return
        if (!ToolManager.diffContainsChange(diff: diff)) {
            return
        }
        
        self.compactLog()
        
        if (logIdx >= 0 && logs[logIdx].type == .hairBrush) {
            log = logs[logIdx] as! HairBrushLog
        }
        else {
            log = HairBrushLog()
            appendLog(log: log)
        }
        
        log.push(diff: diff)
    }
    
    func pushLogOfBrush(previousAlpha: [UInt8], currentAlpha: [UInt8]) {
        var log: BrushLog
        let diff = encodeDiff(from: previousAlpha, to: currentAlpha)
        
        // If diff have no change at all, just return
        if (!ToolManager.diffContainsChange(diff: diff)) {
            return
        }
        
        self.compactLog()
        
        if (logIdx >= 0 && logs[logIdx].type == .brush) {
            log = logs[logIdx] as! BrushLog
        }
        else {
            log = BrushLog()
            appendLog(log: log)
        }
        
        log.push(diff: diff)
    }
    
    func appendLog(log: ToolLog) {
        if (logIdx >= 0) { logSize += logs[logIdx].size }
        logs.append(log)
        logIdx += 1
        
        var count = 0
        while logSize > logSizeThreshold {
            logSize -= logs[count].size
            count += 1
        }
        logs.removeFirst(count)
        logIdx -= count
    }
    
    // Remove elements in logs which are after logIdx
    func compactLog() {
        for i in logIdx+1..<logs.count {
            logSize -= logs[i].size
        }
        logs.removeLast(logs.count - logIdx - 1)
    }
    
    func endProcessing() {
        guard tool != nil else {
            return
        }
        
        // If tool type is different from last log type, just return
        if (logIdx == -1 || tool.type != logs[logIdx].type) {
            tool.endProcessing()
            return
        }

        // Save the state of current tool to log
        switch tool.type {
        case .quickSelect:
            let qstool = tool as! QuickSelectTool
            let log = logs[logIdx] as! QuickSelectLog
            log.encodedMask = encodeArray(array: qstool.mask)
            log.encodedAlpha = encodeArray(array: maskView.opacity)
        case .hairBrush:
            break
        case .brush:
            break
        }
        
        tool.endProcessing()
    }
    
    func invert() {
        if self.isInProcess() {
            return
        }
        
        compactLog()
        
        // If we don't have any log, create one based on tool type
        if (logIdx == -1) {
            self.appendLog(log: ToolManager.createLog(type: tool.type))
        }
        
        switchTool(type: logs[logIdx].type)
        
        tool.invert()
        logs[logIdx].invert()
    }
    
    func undo() {
        guard !isInProcess() && canPerformUndo() else {
            return
        }

        switchTool(type: logs[logIdx].type)
        logs[logIdx].undo(tool: tool)
        
        // If current log contains no changes, set logIdx to previous log
        if logs[logIdx].idx == -1 {
            logIdx -= 1
        }
        tool.refresh()
    }
    
    func redo() {
        guard !isInProcess() && canPerformRedo() else {
            return
        }
        
        if (logIdx == -1) {
            logIdx = 0
        }
        else if (logs[logIdx].idx + 1 >= logs[logIdx].count) {
            self.endProcessing()
            logIdx += 1
        }
        
        
        switchTool(type: logs[logIdx].type)
        logs[logIdx].redo(tool: tool)
        tool.refresh()
    }
    
    func canPerformUndo() -> Bool {
        return logIdx >= 0 && logs[logIdx].idx >= 0
    }
    
    func canPerformRedo() -> Bool {
        return logIdx + 1 < logs.count || (logIdx >= 0 && logs[logIdx].idx + 1 < logs[logIdx].count)
    }
    
    func switchTool(type: TCMaskTool) {
        if (tool != nil && tool.type == type) {
            return
        }

        self.endProcessing()
        
        switch type {
        case .quickSelect:
            let qstool = QuickSelectTool(maskView: maskView, toolManager: self)

            if (logIdx >= 0 && logs[logIdx] is QuickSelectLog && logs[logIdx].idx >= 0) {
                let log = logs[logIdx] as! QuickSelectLog
                
                if (log.encodedMask == nil) {
                    // nothing to do
                }
                
                TCCore.logDecodeArray(&qstool.mask, encoded: log.encodedMask, decodedCount: qstool.mask.count, encodedCount: log.encodedMask.count)
                TCCore.logDecodeArray(&maskView.opacity, encoded: log.encodedAlpha, decodedCount: maskView.opacity.count, encodedCount: log.encodedAlpha.count)
                TCCore.arrayCopy(&qstool.previousMask, src: qstool.mask, count: qstool.mask.count)
                log.encodedAlpha = nil
                log.encodedMask = nil
            }
            qstool.refresh()
            tool = qstool

        case .hairBrush:
            tool = HairBrushTool(maskView: maskView, toolManager: self)
            
        case .brush:
            tool = BrushTool(maskView: maskView, toolManager: self)
        }
        
        tool.delegate = toolDelegate
    }
    
    func isInProcess() -> Bool {
        if tool == nil {
            return false
        }
        
        switch tool.type {
        case .brush, .hairBrush:
            return false
        case .quickSelect:
            return (tool as! QuickSelectTool).isSelectRunning
        }
    }
    
    // Create tool log based on type
    static func createLog(type: TCMaskTool) -> ToolLog {
        switch type {
        case .quickSelect:
            return QuickSelectLog()
        case .hairBrush:
            return HairBrushLog()
        case .brush:
            return BrushLog()
        }
    }
    
    static func diffContainsChange(diff: [UInt32]) -> Bool {
        for v in diff {
            if (v & 0xFF != 0) {
                return true
            }
        }
        return false
    }
}
