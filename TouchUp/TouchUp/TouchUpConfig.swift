import Foundation

/// Centralized configuration for TouchUp timing and behavior constants
struct TouchUpConfig {
    
    // MARK: - Text Replacement Timing
    
    /// Time to wait for the original app to become active after preview window closes
    /// Reduce this for faster UX, increase if app activation is unreliable
    static let appActivationDelay: TimeInterval = 0.15 // 150ms (optimized from 300ms)
    
    /// Time to wait after paste command before considering it complete
    /// Reduce this for faster UX, increase if paste operations fail
    static let pasteCompletionDelay: TimeInterval = 0.10 // 100ms (optimized from 150ms)
    
    // MARK: - Selection Reading Timing
    
    /// Time to wait after simulating copy command for clipboard to update
    /// Used when Accessibility API fails and we fall back to Cmd+C
    static let copyCompletionDelay: TimeInterval = 0.10 // 100ms
    
    // MARK: - Accessibility API
    
    /// Whether to attempt Accessibility API before falling back to clipboard
    /// Set to false to always use clipboard method (more compatible but slower)
    static let useAccessibilityAPI: Bool = true
    
    // MARK: - Helper Methods
    
    /// Convert TimeInterval (seconds) to nanoseconds for Task.sleep
    static func nanoseconds(_ seconds: TimeInterval) -> UInt64 {
        return UInt64(seconds * 1_000_000_000)
    }
}
