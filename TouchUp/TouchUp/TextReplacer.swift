//
//  TextReplacer.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Cocoa
import os

/// Replaces selected text with polished output
/// Uses clipboard + simulated Cmd+V approach
class TextReplacer {
    
    private let clipboardManager: ClipboardManager
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
    }
    
    // MARK: - Public Methods
    
    /// Replace the current selection with the given text
    /// - Parameter text: Text to paste over selection
    func replaceSelection(with text: String) async throws {
        appLogger.info("Replacing selection with polished text (\(text.count) chars)")
        
        // Set clipboard to polished text
        clipboardManager.setClipboard(text)
        
        // Simulate Cmd+V to paste
        await simulatePasteCommand()
        
        // Wait for paste to complete
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        appLogger.info("Selection replaced successfully")
    }
    
    // MARK: - Private Methods
    
    /// Simulate Cmd+V keystroke to paste
    private func simulatePasteCommand() async {
        // Create Cmd+V key down event
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 9, // 'V' key
            keyDown: true
        ) else {
            appLogger.error("Failed to create Cmd+V key down event")
            return
        }
        
        // Set Command flag
        keyDown.flags = .maskCommand
        
        // Create Cmd+V key up event
        guard let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 9, // 'V' key
            keyDown: false
        ) else {
            appLogger.error("Failed to create Cmd+V key up event")
            return
        }
        
        keyUp.flags = .maskCommand
        
        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        appLogger.debug("Simulated Cmd+V keystroke")
    }
}
