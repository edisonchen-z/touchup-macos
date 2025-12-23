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
    
    // Weak reference to AppDelegate for menu bar icon updates
    private weak var appDelegate: AppDelegate?
    
    // MARK: - Initialization
    
    init(appDelegate: AppDelegate? = nil) {
        self.appDelegate = appDelegate
        self.clipboardManager = ClipboardManager()
        self.selectionReader = SelectionReader(clipboardManager: clipboardManager)
        self.ollamaClient = OllamaClient()
        self.textReplacer = TextReplacer(clipboardManager: clipboardManager)
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
        
        // Step 2: Update menu bar icon to "processing" state
        appDelegate?.setMenuBarIconProcessing()
        
        // Step 3: Send to Ollama for polishing
        do {
            let polishedText = try await ollamaClient.polishText(selectedText)
            appLogger.info("Text polished successfully (\(polishedText.count) chars)")
            
            // Step 4: Replace selection with polished text
            try await textReplacer.replaceSelection(with: polishedText)
            
            // Step 5: Restore original clipboard
            clipboardManager.restoreClipboard(clipboardSnapshot)
            appLogger.debug("Original clipboard restored")
            
            // Step 6: Update menu bar icon to "success" state
            appDelegate?.setMenuBarIconSuccess()
            
            let duration = Date().timeIntervalSince(workflowStartTime) * 1000
            appLogger.notice("Polish workflow completed in \(String(format: "%.0f", duration))ms")
            
            if let startTime = startTime {
                let turnaroundTime = Date().timeIntervalSince(startTime) * 1000
                appLogger.notice("Turnaround Time: \(String(format: "%.0f", turnaroundTime))ms")
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
            appLogger.error("Model not found: qwen2.5:3b")
            notificationManager.showModelNotFoundAlert(model: "qwen2.5:3b")
            
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
}
