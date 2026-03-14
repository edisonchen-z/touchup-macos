import Cocoa
import SwiftUI
import os

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?
    private var polishOrchestrator: PolishOrchestrator?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set the icon to an SF Symbol
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "pencil.line", accessibilityDescription: "TouchUp")
        }
        
        // Create the menu
        let menu = NSMenu()
        
        // Settings menu item
        let settingsItem = NSMenuItem(
            title: "TouchUp Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(settingsItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Quit menu item
        let quitItem = NSMenuItem(
            title: "Quit TouchUp",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        // Attach menu to status item
        statusItem?.menu = menu
        
        // Emit startup logs
        appLogger.notice("TouchUp launched and running")
        appLogger.info("Menu bar icon initialized with Settings and Quit options")
        
        // Initialize polish orchestrator
        polishOrchestrator = PolishOrchestrator(appDelegate: self)
        
        // Initialize hotkey manager
        setupHotkey()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up hotkey manager
        hotkeyManager?.unregister()
        appLogger.info("TouchUp shutting down")
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "TouchUp Settings"
            window.contentViewController = hostingController
            window.center()
            window.isReleasedWhenClosed = false
            
            self.settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Hotkey Management
    
    private func setupHotkey() {
        hotkeyManager = HotkeyManager()
        
        // Attempt to register hotkey
        let success = hotkeyManager?.register { [weak self] startTime in
            self?.handleHotkeyPressed(startTime: startTime)
        }
        
        if success == true {
            appLogger.info("Hotkey setup complete")
        } else {
            // Permission denied - prompt user
            appLogger.warning("Hotkey registration failed - prompting for permission")
            hotkeyManager?.promptForAccessibilityPermission()
        }
        
        // Listen for hotkey changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeyChanged),
            name: Notification.Name("HotkeyChanged"),
            object: nil
        )
    }
    
    @objc private func handleHotkeyChanged() {
        appLogger.info("Received hotkey change notification")
        hotkeyManager?.updateHotkey()
    }
    
    private func handleHotkeyPressed(startTime: Date) {
        appLogger.notice("Hotkey pressed - polish workflow triggered")
        
        // Execute polish workflow asynchronously
        Task {
            await polishOrchestrator?.polishSelectedText(startTime: startTime)
        }
    }
    
    
    // MARK: - Menu Bar Icon States
    
    /// Update menu bar icon to show processing state
    func setMenuBarIconProcessing() {
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "TouchUp Processing")
                appLogger.debug("Menu bar icon: processing")
            }
        }
    }
    
    /// Update menu bar icon to show success state (briefly)
    func setMenuBarIconSuccess() {
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "TouchUp Success")
                appLogger.debug("Menu bar icon: success")
                
                // Revert to normal after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.setMenuBarIconNormal()
                }
            }
        }
    }
    
    /// Update menu bar icon to show error state (briefly)
    func setMenuBarIconError() {
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "TouchUp Error")
                appLogger.debug("Menu bar icon: error")
                
                // Revert to normal after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.setMenuBarIconNormal()
                }
            }
        }
    }
    
    /// Update menu bar icon to show awaiting input state
    func setMenuBarIconAwaitingInput() {
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "TouchUp Awaiting Input")
                appLogger.debug("Menu bar icon: awaiting input")
            }
        }
    }
    
    /// Reset menu bar icon to normal state
    func setMenuBarIconNormal() {
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "pencil.line", accessibilityDescription: "TouchUp")
                appLogger.debug("Menu bar icon: normal")
            }
        }
    }
}

