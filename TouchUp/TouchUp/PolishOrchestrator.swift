//
//  PolishOrchestrator.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Cocoa
import os

/// Orchestrates the entire text polishing workflow
/// Coordinates selection reading, Ollama processing, and text replacement
class PolishOrchestrator {
    
    // MARK: - Dependencies
    
    private let clipboardManager: ClipboardManager
    private let selectionReader: SelectionReader
    private let ollamaClient: OllamaClient
    private let textReplacer: TextReplacer
    private let notificationManager = NotificationManager.shared
    private let previewManager: PreviewWindowManager
    
    // Weak reference to AppDelegate for menu bar icon updates
    private weak var appDelegate: AppDelegate?
    
    // MARK: - Initialization
    
    init(appDelegate: AppDelegate? = nil) {
        self.appDelegate = appDelegate
        self.clipboardManager = ClipboardManager()
        self.selectionReader = SelectionReader(clipboardManager: clipboardManager)
        self.ollamaClient = OllamaClient()
        self.textReplacer = TextReplacer(clipboardManager: clipboardManager)
        self.previewManager = PreviewWindowManager()
    }
    
    // MARK: - Public Methods
    
    /// Execute the text polishing workflow
    func polishSelectedText(startTime: Date? = nil) async {
        let workflowStartTime = Date()
        appLogger.notice("Starting polish workflow")
        
        // Save clipboard before we start (in case we use clipboard for reading/replacing)
        let clipboardSnapshot = clipboardManager.saveClipboard()
        
        // Step 1: Read selected text
        guard let selectedText = await selectionReader.readSelectedText() else {
            // No selection - exit silently (no notification)
            appLogger.info("No selection detected - workflow aborted")
            return
        }
        
        appLogger.info("Selected text captured: \(selectedText.count) characters")
        
        // Step 2: Remember the frontmost application (before preview steals focus)
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        appLogger.debug("Captured frontmost app: \(frontmostApp?.localizedName ?? "unknown")")
        
        // Step 3: Update menu bar icon to "processing" state
        appDelegate?.setMenuBarIconProcessing()
        
        // Step 4: Send to Ollama for polishing
        do {
            let polishedText = try await ollamaClient.polishText(selectedText)
            appLogger.info("Text polished successfully (\(polishedText.count) chars)")
            
            // Step 4: Show preview window and wait for user decision
            appDelegate?.setMenuBarIconAwaitingInput()
            
            let cursorPosition = getCurrentCursorPosition()
            let accepted = await previewManager.showPreview(
                original: selectedText,
                polished: polishedText,
                cursorPosition: cursorPosition
            )
            
            if accepted {
                // User accepted - replace the text
                appLogger.info("User accepted - replacing text")
                let replacementStartTime = Date()
                
                // Reactivate the original application
                let activationStartTime = Date()
                if let app = frontmostApp {
                    app.activate(options: [])
                    appLogger.debug("Reactivated original app: \(app.localizedName ?? "unknown")")
                }
                
                // Wait for app to become active
                try? await Task.sleep(nanoseconds: TouchUpConfig.nanoseconds(TouchUpConfig.appActivationDelay))
                let activationDuration = Date().timeIntervalSince(activationStartTime) * 1000
                appLogger.debug("App activation took \(String(format: "%.0f", activationDuration))ms")
                
                // Try to replace text using Accessibility API
                let apiStartTime = Date()
                let success = await replaceTextViaAccessibility(
                    originalText: selectedText,
                    newText: polishedText
                )
                
                if success {
                    let apiDuration = Date().timeIntervalSince(apiStartTime) * 1000
                    appLogger.info("✅ Text replaced via Accessibility API in \(String(format: "%.0f", apiDuration))ms")
                } else {
                    let apiDuration = Date().timeIntervalSince(apiStartTime) * 1000
                    appLogger.debug("Accessibility API attempt took \(String(format: "%.0f", apiDuration))ms (failed)")
                    
                    // Fallback: use clipboard paste method
                    appLogger.warning("Accessibility API failed, using clipboard fallback")
                    let fallbackStartTime = Date()
                    try await textReplacer.replaceSelection(with: polishedText)
                    let fallbackDuration = Date().timeIntervalSince(fallbackStartTime) * 1000
                    appLogger.info("✅ Text replaced via clipboard fallback in \(String(format: "%.0f", fallbackDuration))ms")
                }
                
                let totalReplacementDuration = Date().timeIntervalSince(replacementStartTime) * 1000
                appLogger.notice("📊 Total replacement time: \(String(format: "%.0f", totalReplacementDuration))ms")
                
                // Step 5a: (Text replacement done above)
                
                // Step 6a: Restore original clipboard
                clipboardManager.restoreClipboard(clipboardSnapshot)
                appLogger.debug("Original clipboard restored")
                
                // Step 7a: Update menu bar icon to "success" state
                appDelegate?.setMenuBarIconSuccess()
                
                let duration = Date().timeIntervalSince(workflowStartTime) * 1000
                appLogger.notice("Polish workflow completed (accepted) in \(String(format: "%.0f", duration))ms")
                
                if let startTime = startTime {
                    let turnaroundTime = Date().timeIntervalSince(startTime) * 1000
                    appLogger.notice("Turnaround Time: \(String(format: "%.0f", turnaroundTime))ms")
                }
            } else {
                // User rejected - keep original text
                appLogger.info("User rejected - keeping original text")
                
                // Reactivate the original application so focus returns
                if let app = frontmostApp {
                    app.activate(options: [])
                    appLogger.debug("Reactivated original app after reject: \(app.localizedName ?? "unknown")")
                }
                
                // No need to restore clipboard - we never modified it in Reject path
                
                // Step 5b: Update menu bar icon to normal state
                appDelegate?.setMenuBarIconNormal()
                
                let duration = Date().timeIntervalSince(workflowStartTime) * 1000
                appLogger.notice("Polish workflow completed (rejected) in \(String(format: "%.0f", duration))ms")
            }
            
        } catch let error as OllamaError {
            // Restore clipboard even on error
            clipboardManager.restoreClipboard(clipboardSnapshot)
            
            // Update icon to error state
            appDelegate?.setMenuBarIconError()
            
            // Handle error with appropriate notification
            handleOllamaError(error)
            
        } catch {
            // Restore clipboard even on error
            clipboardManager.restoreClipboard(clipboardSnapshot)
            
            // Update icon to error state
            appDelegate?.setMenuBarIconError()
            
            appLogger.error("Unexpected error: \(error.localizedDescription)")
            notificationManager.showNotification(
                title: "TouchUp",
                message: "An error occurred"
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle Ollama-specific errors
    private func handleOllamaError(_ error: OllamaError) {
        switch error {
        case .connectionFailed:
            appLogger.error("Ollama connection failed")
            notificationManager.showOllamaSetupAlert()
            
        case .modelNotFound:
            let model = SettingsManager.shared.getSelectedModel()
            appLogger.error("Model not found: \(model)")
            notificationManager.showModelNotFoundAlert(model: model)
            
        case .timeout:
            appLogger.error("Ollama request timeout")
            notificationManager.showNotification(
                title: "TouchUp",
                message: "Text polishing timed out"
            )
            
        case .emptyResponse:
            appLogger.error("Empty response from Ollama")
            // Silent - just log
            
        case .invalidResponse, .serverError:
            appLogger.error("Ollama error: \(error.localizedDescription)")
            notificationManager.showNotification(
                title: "TouchUp",
                message: "Text polishing failed"
            )
        }
    }
    
    /// Get the current cursor/mouse position for window placement
    private func getCurrentCursorPosition() -> CGPoint? {
        return NSEvent.mouseLocation
    }
    
    /// Replace text using Accessibility API
    /// - Parameters:
    ///   - originalText: The original text that should be replaced
    ///   - newText: The new text to insert
    /// - Returns: true if successful, false otherwise
    private func replaceTextViaAccessibility(originalText: String, newText: String) async -> Bool {
        let methodStartTime = Date()
        
        // Get the system-wide accessibility object
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Get the focused UI element
        let getFocusedStartTime = Date()
        var focusedElement: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        let getFocusedDuration = Date().timeIntervalSince(getFocusedStartTime) * 1000
        appLogger.debug("  ⏱️ Get focused element: \(String(format: "%.1f", getFocusedDuration))ms")
        
        guard focusedResult == .success,
              let element = focusedElement else {
            appLogger.warning("No focused UI element found for text replacement")
            return false
        }
        
        let axElement = element as! AXUIElement
        
        // Try to get the current value
        let getValueStartTime = Date()
        var currentValue: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(
            axElement,
            kAXValueAttribute as CFString,
            &currentValue
        )
        
        let getValueDuration = Date().timeIntervalSince(getValueStartTime) * 1000
        appLogger.debug("  ⏱️ Read value attribute: \(String(format: "%.1f", getValueDuration))ms")
        
        if valueResult == .success,
           let value = currentValue as? String {
            // Find and replace the original text in the value
            if let range = value.range(of: originalText) {
                let newValue = value.replacingCharacters(in: range, with: newText)
                
                // Set the new value
                let setValueStartTime = Date()
                let setValue = AXUIElementSetAttributeValue(
                    axElement,
                    kAXValueAttribute as CFString,
                    newValue as CFTypeRef
                )
                
                let setValueDuration = Date().timeIntervalSince(setValueStartTime) * 1000
                appLogger.debug("  ⏱️ Set value attribute: \(String(format: "%.1f", setValueDuration))ms")
                
                if setValue == .success {
                    let totalDuration = Date().timeIntervalSince(methodStartTime) * 1000
                    appLogger.info("Successfully replaced text via Accessibility API (total: \(String(format: "%.1f", totalDuration))ms)")
                    return true
                } else {
                    appLogger.warning("Failed to set value via Accessibility API: \(setValue.rawValue)")
                }
            } else {
                appLogger.warning("Original text not found in current value")
            }
        } else {
            appLogger.debug("Could not get value attribute, result: \(valueResult.rawValue)")
        }
        
        return false
    }
}



