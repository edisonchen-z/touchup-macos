//
//  HotkeyManager.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Cocoa
import os

/// Manages global hotkey registration using CGEventTap
/// Detects Cmd+Option+T system-wide and triggers the polish workflow
class HotkeyManager {
    // MARK: - Properties
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotkeyAction: ((Date) -> Void)?
    
    // Dynamic hotkey
    private var targetKeyCode: CGKeyCode
    private var targetModifiers: CGEventFlags
    
    // MARK: - Initialization
    
    init() {
        // Initialize with settings
        self.targetKeyCode = CGKeyCode(SettingsManager.shared.hotkeyKeyCode)
        self.targetModifiers = CGEventFlags(rawValue: UInt64(SettingsManager.shared.hotkeyModifiers))
        
        appLogger.info("HotkeyManager initialized with hotkey: \(SettingsManager.shared.hotkeyString)")
    }
    
    deinit {
        unregister()
    }
    
    // MARK: - Public Methods
    
    /// Update the hotkey configuration and re-register
    /// Update the hotkey configuration and re-register
    func updateHotkey() {
        // Capture existing action before unregistering (which clears it)
        let savedAction = self.hotkeyAction
        
        unregister()
        
        self.targetKeyCode = CGKeyCode(SettingsManager.shared.hotkeyKeyCode)
        self.targetModifiers = CGEventFlags(rawValue: UInt64(SettingsManager.shared.hotkeyModifiers))
        
        appLogger.info("HotkeyManager updated to: \(SettingsManager.shared.hotkeyString)")
        
        // Re-register if we had an action
        if let action = savedAction {
            _ = register(action: action)
        }
    }
    
    /// Register the global hotkey with a callback action
    /// - Parameter action: Closure to execute when hotkey is pressed
    /// - Returns: True if registration succeeded, false otherwise
    func register(action: @escaping (Date) -> Void) -> Bool {
        // Check for accessibility permission first
        guard checkAccessibilityPermission() else {
            appLogger.warning("Cannot register hotkey - Accessibility permission denied")
            return false
        }
        
        self.hotkeyAction = action
        
        // Create event tap to monitor key events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Extract HotkeyManager instance from refcon
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            appLogger.error("Failed to create CGEventTap - check Accessibility permissions")
            return false
        }
        
        self.eventTap = tap
        
        // Create run loop source and add to current run loop
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: tap, enable: true)
        
        appLogger.notice("Global hotkey registered: \(SettingsManager.shared.hotkeyString)")
        return true
    }
    
    /// Unregister the hotkey and clean up
    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            appLogger.info("Global hotkey unregistered")
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        hotkeyAction = nil
    }
    
    /// Check if app has Accessibility permission
    /// - Returns: True if permission granted, false otherwise
    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        appLogger.info("Accessibility permission: \(trusted ? "granted" : "denied")")
        return trusted
    }
    
    /// Prompt user to grant Accessibility permission
    func promptForAccessibilityPermission() {
        appLogger.info("Prompting user for Accessibility permission")
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        TouchUp needs Accessibility permission to:
        • Detect your global hotkey (Cmd+Option+T)
        • Read and replace selected text
        
        Your text stays completely private and is processed locally.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility pane
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                appLogger.info("Opened System Settings for Accessibility permission")
            }
        } else {
            appLogger.info("User dismissed Accessibility permission prompt")
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle keyboard events from the event tap
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Check if event is a key down
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        // Get the key code and modifier flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        
        // Check if this is our target hotkey
        // We need to match the flags exactly, masking out non-modifier flags (like caps lock, num lock etc usually not relevant but handled by mask)
        // Important: CGEventFlags contains device-independent flags and others. 
        // We'll trust targetModifiers set from SettingsManager (NSEvent flags) matches CGEvent flags for major modifiers.
        
        // Convert NSEvent modifier flags to CGEventFlags logically for comparison
        // The raw values are compatible for the main modifiers: Command, Option, Control, Shift.
        
        let currentFlags = event.flags
        let requiredFlags = targetModifiers
        
        // Define mask for relevant modifiers: Shift, Control, Option, Command
        let relevantMask: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskCommand]
        
        let maskedCurrent = currentFlags.intersection(relevantMask)
        let maskedTarget = requiredFlags.intersection(relevantMask)
        
        let isFlagMatch = maskedCurrent == maskedTarget
        let isKeyMatch = keyCode == targetKeyCode
        
        if isFlagMatch && isKeyMatch {
            // Hotkey detected!
            let now = Date()
            appLogger.notice("Hotkey triggered - \(SettingsManager.shared.hotkeyString) pressed")
            
            // Execute the action on the main thread
            DispatchQueue.main.async { [weak self] in
                self?.hotkeyAction?(now)
            }
            
            // Consume the event to prevent it from reaching other apps
            return nil
        }
        
        // Pass through other events
        return Unmanaged.passUnretained(event)
    }
}
