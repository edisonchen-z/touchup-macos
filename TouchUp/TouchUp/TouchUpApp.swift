import SwiftUI

@main
struct TouchUpApp: App {
    // Attach AppDelegate for menu bar and status item management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No window group needed as this is a menu bar app
        // Settings are handled via AppDelegate
        Settings {
            EmptyView()
        }
    }
}
