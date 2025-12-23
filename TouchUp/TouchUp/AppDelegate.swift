//
//  AppDelegate.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Cocoa
import os

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set the icon to an SF Symbol
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "TouchUp")
        }
        
        // Create the menu
        let menu = NSMenu()
        
        // Settings menu item
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(settingsItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Quit menu item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        // Attach menu to status item
        statusItem?.menu = menu
        
        // Emit startup logs
        appLogger.notice("TouchUp launched and running")
        appLogger.info("Menu bar icon initialized with Settings and Quit options")
    }
    
    @objc private func openSettings() {
        // Open Settings window using the SwiftUI Settings scene
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
