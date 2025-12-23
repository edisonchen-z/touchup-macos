//
//  TouchUpApp.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import SwiftUI

@main
struct TouchUpApp: App {
    // Attach AppDelegate for menu bar and status item management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings scene for Settings window
        Settings {
            SettingsView()
        }
    }
}
