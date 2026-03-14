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
        let startTime = Date()
        
        // Set clipboard to polished text
        let clipboardStartTime = Date()
        clipboardManager.setClipboard(text)
        let clipboardDuration = Date().timeIntervalSince(clipboardStartTime) * 1000
        appLogger.debug("  ⏱️ Set clipboard: \(String(format: "%.1f", clipboardDuration))ms")
        
        // Simulate Cmd+V to paste
        let pasteStartTime = Date()
        await simulatePasteCommand()
        
        // Wait for paste to complete
        try? await Task.sleep(nanoseconds: TouchUpConfig.nanoseconds(TouchUpConfig.pasteCompletionDelay))
        let pasteDuration = Date().timeIntervalSince(pasteStartTime) * 1000
        appLogger.debug("  ⏱️ Paste operation: \(String(format: "%.1f", pasteDuration))ms")
        
        let totalDuration = Date().timeIntervalSince(startTime) * 1000
        appLogger.info("Selection replaced successfully (total: \(String(format: "%.1f", totalDuration))ms)")
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
