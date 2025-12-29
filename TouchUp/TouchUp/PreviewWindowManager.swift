//
//  PreviewWindowManager.swift
//  TouchUp
//
//  Created by Edison Chen on 12/26/25.
//

import Cocoa
import SwiftUI
import os

/// Manages the lifecycle of the preview window
/// Handles showing/hiding the window and bridging user decisions to async/await
class PreviewWindowManager {
    
    // MARK: - Properties
    
    private var currentWindow: NSWindow?
    private var windowDelegate: WindowCloseDelegate?
    private var hasResponded = false
    
    // MARK: - Public Methods
    
    /// Show the preview window and wait for user decision
    /// - Parameters:
    ///   - original: Original text before polishing
    ///   - polished: Polished text from Ollama
    ///   - cursorPosition: Optional cursor position for window placement
    /// - Returns: true if user accepted, false if rejected
    func showPreview(
        original: String,
        polished: String,
        cursorPosition: CGPoint? = nil
    ) async -> Bool {
        appLogger.info("Showing preview window")
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Close any existing window first
                self.closeCurrentWindow()
                
                // Create the window
                let (window, delegate) = self.createWindow(
                    original: original,
                    polished: polished,
                    onAccept: {
                        guard !self.hasResponded else { return }
                        self.hasResponded = true
                        appLogger.notice("User accepted polished text")
                        continuation.resume(returning: true)
                        self.closeCurrentWindow()
                    },
                    onReject: {
                        guard !self.hasResponded else { return }
                        self.hasResponded = true
                        appLogger.notice("User rejected polished text")
                        continuation.resume(returning: false)
                        self.closeCurrentWindow()
                    }
                )
                
                // Position the window
                self.positionWindow(window, near: cursorPosition)
                
                // Show the window
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                
                self.currentWindow = window
                self.windowDelegate = delegate
                self.hasResponded = false // Reset flag for this new window
                appLogger.debug("Preview window displayed")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Create the NSWindow with SwiftUI content
    private func createWindow(
        original: String,
        polished: String,
        onAccept: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) -> (window: NSWindow, delegate: WindowCloseDelegate) {
        // Create the SwiftUI view
        let contentView = PreviewWindow(
            originalText: original,
            polishedText: polished,
            onAccept: onAccept,
            onReject: onReject
        )
        
        // Wrap in hosting view
        let hostingView = NSHostingView(rootView: contentView)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 450),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "TouchUp Suggestions"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.level = .floating // Stay above other windows
        window.isMovableByWindowBackground = true
        
        // Handle window close button - store strong reference to prevent deallocation
        let delegate = WindowCloseDelegate(onClose: onReject)
        window.delegate = delegate
        
        return (window, delegate)
    }
    
    /// Position the window near the cursor or center on screen
    private func positionWindow(_ window: NSWindow, near cursorPosition: CGPoint?) {
        if let cursorPosition = cursorPosition {
            // Position near cursor, but ensure it's on screen
            var origin = cursorPosition
            
            // Offset slightly to avoid covering cursor
            origin.x += 20
            origin.y -= 20
            
            // Get screen bounds
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                
                // Ensure window doesn't go off right edge
                if origin.x + windowFrame.width > screenFrame.maxX {
                    origin.x = screenFrame.maxX - windowFrame.width - 20
                }
                
                // Ensure window doesn't go off left edge
                if origin.x < screenFrame.minX {
                    origin.x = screenFrame.minX + 20
                }
                
                // Ensure window doesn't go off bottom edge
                if origin.y - windowFrame.height < screenFrame.minY {
                    origin.y = screenFrame.minY + windowFrame.height + 20
                }
                
                // Ensure window doesn't go off top edge
                if origin.y > screenFrame.maxY {
                    origin.y = screenFrame.maxY - 20
                }
                
                window.setFrameTopLeftPoint(origin)
            } else {
                // Fallback to center if no screen info
                window.center()
            }
        } else {
            // No cursor position - center on screen
            window.center()
        }
        
        appLogger.debug("Window positioned at (\(window.frame.origin.x), \(window.frame.origin.y))")
    }
    
    /// Close the current window if it exists
    private func closeCurrentWindow() {
        if let window = currentWindow {
            window.close()
            currentWindow = nil
            windowDelegate = nil
            appLogger.debug("Closed preview window")
        }
    }
}

// MARK: - Window Delegate

/// Delegate to handle window close button
private class WindowCloseDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        appLogger.debug("Preview window closed via close button")
        onClose()
    }
}
