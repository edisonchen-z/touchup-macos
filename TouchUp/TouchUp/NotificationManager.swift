import UserNotifications
import Cocoa
import os

/// Manages system notifications and user alerts
class NotificationManager {
    
    static let shared = NotificationManager()
    
    // Preference keys for "Don't show again" alerts
    private let dontShowOllamaSetupKey = "dontShowOllamaSetup"
    private let dontShowModelNotFoundKey = "dontShowModelNotFound"
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Setup
    
    /// Request permission to show notifications
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                appLogger.info("Notification permission granted")
            } else {
                appLogger.warning("Notification permission denied")
            }
        }
    }
    
    // MARK: - System Notifications
    
    /// Show a system notification
    func showNotification(title: String, message: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = nil // Silent notifications
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                appLogger.error("Failed to show notification: \(error.localizedDescription)")
            } else {
                appLogger.debug("Notification shown: \(message)")
            }
        }
    }
    
    // MARK: - Setup Alerts (with "Don't show again")
    
    /// Show Ollama setup alert (first time only)
    func showOllamaSetupAlert() {
        guard !UserDefaults.standard.bool(forKey: dontShowOllamaSetupKey) else {
            appLogger.debug("Skipping Ollama setup alert (user dismissed it)")
            showNotification(title: "TouchUp", message: "Ollama not running")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Ollama Not Running"
        alert.informativeText = """
        TouchUp requires Ollama to polish text.
        
        Start Ollama with:
          ollama serve
        
        Or install it from: https://ollama.ai
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Don't Show Again")
        alert.showsSuppressionButton = false
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            UserDefaults.standard.set(true, forKey: dontShowOllamaSetupKey)
            appLogger.info("User dismissed Ollama setup alert permanently")
        }
    }
    
    /// Show model not found alert (first time only)
    func showModelNotFoundAlert(model: String) {
        guard !UserDefaults.standard.bool(forKey: dontShowModelNotFoundKey) else {
            appLogger.debug("Skipping model not found alert (user dismissed it)")
            showNotification(title: "TouchUp", message: "Model '\(model)' not found")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Model Not Found"
        alert.informativeText = """
        The model '\(model)' is not installed.
        
        Pull it with:
          ollama pull \(model)
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Don't Show Again")
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            UserDefaults.standard.set(true, forKey: dontShowModelNotFoundKey)
            appLogger.info("User dismissed model not found alert permanently")
        }
    }
    
    // MARK: - Reset Preferences
    
    /// Reset all "Don't show again" preferences (for testing/settings)
    func resetDismissedAlerts() {
        UserDefaults.standard.removeObject(forKey: dontShowOllamaSetupKey)
        UserDefaults.standard.removeObject(forKey: dontShowModelNotFoundKey)
        appLogger.info("Reset all dismissed alerts")
    }
}
