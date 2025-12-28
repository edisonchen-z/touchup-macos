//
//  SelectionReader.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Cocoa
import os

/// Reads currently selected text from the active application
/// Uses Accessibility API first, falls back to clipboard copy if needed
class SelectionReader {
    
    private let clipboardManager: ClipboardManager
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
    }
    
    // MARK: - Public Methods
    
    /// Read the currently selected text
    /// - Returns: Selected text if available, nil if no selection or error
    func readSelectedText() async -> String? {
        // Try Accessibility API first
        if let text = readViaAccessibility() {
            appLogger.debug("Selected text read via Accessibility API (\(text.count) chars)")
            return text
        }
        
        // Fall back to clipboard copy
        appLogger.debug("Accessibility API failed, falling back to clipboard copy")
        if let text = await readViaClipboard() {
            appLogger.debug("Selected text read via clipboard (\(text.count) chars)")
            return text
        }
        
        appLogger.info("No selection detected - ignoring hotkey")
        return nil
    }
    
    // MARK: - Private Methods
    
    /// Attempt to read selected text via Accessibility API
    private func readViaAccessibility() -> String? {
        // Get the system-wide accessibility object
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Get the focused UI element
        var focusedElement: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard focusedResult == .success,
              let element = focusedElement else {
            appLogger.debug("No focused UI element found")
            return nil
        }
        
        // Try to get the selected text attribute
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        if textResult == .success,
           let text = selectedText as? String,
           !text.isEmpty {
            return text
        }
        
        appLogger.debug("No selected text found via Accessibility API")
        return nil
    }
    
    /// Read selected text by simulating Cmd+C and reading the clipboard
    private func readViaClipboard() async -> String? {
        // Save current clipboard
        let snapshot = clipboardManager.saveClipboard()
        
        // Simulate Cmd+C to copy selection
        await simulateCopyCommand()
        
        // Wait a bit for the copy to complete
        try? await Task.sleep(nanoseconds: TouchUpConfig.nanoseconds(TouchUpConfig.copyCompletionDelay))
        
        // Read the clipboard
        let text = clipboardManager.getClipboardText()
        
        // Restore original clipboard
        clipboardManager.restoreClipboard(snapshot)
        
        // Check if we got text and it's different from what was there before
        guard let text = text, !text.isEmpty else {
            return nil
        }
        
        return text
    }
    
    /// Simulate Cmd+C keystroke to copy selected text
    private func simulateCopyCommand() async {
        // Create Cmd+C key down event
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 8, // 'C' key
            keyDown: true
        ) else {
            appLogger.error("Failed to create Cmd+C key down event")
            return
        }
        
        // Set Command flag
        keyDown.flags = .maskCommand
        
        // Create Cmd+C key up event
        guard let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 8, // 'C' key
            keyDown: false
        ) else {
            appLogger.error("Failed to create Cmd+C key up event")
            return
        }
        
        keyUp.flags = .maskCommand
        
        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        appLogger.debug("Simulated Cmd+C keystroke")
    }
}
