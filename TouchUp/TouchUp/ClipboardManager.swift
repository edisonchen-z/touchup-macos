import Cocoa
import os

/// Snapshot of clipboard state for preservation
struct ClipboardSnapshot {
    let changeCount: Int
    let items: [NSPasteboardItem]
}

/// Manages clipboard operations with preservation support
class ClipboardManager {
    
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Public Methods
    
    /// Save the current clipboard state
    /// - Returns: Snapshot of current clipboard
    func saveClipboard() -> ClipboardSnapshot {
        let changeCount = pasteboard.changeCount
        
        // Get all items from the pasteboard
        let items = pasteboard.pasteboardItems ?? []
        
        // Create copies of the items to preserve them
        let copiedItems = items.compactMap { item -> NSPasteboardItem? in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
        
        appLogger.debug("Saved clipboard snapshot (changeCount: \(changeCount), items: \(copiedItems.count))")
        return ClipboardSnapshot(changeCount: changeCount, items: copiedItems)
    }
    
    /// Restore a previously saved clipboard state
    /// - Parameter snapshot: The snapshot to restore
    func restoreClipboard(_ snapshot: ClipboardSnapshot) {
        // Clear the pasteboard
        pasteboard.clearContents()
        
        // Restore all items
        if !snapshot.items.isEmpty {
            pasteboard.writeObjects(snapshot.items)
            appLogger.debug("Restored clipboard (\(snapshot.items.count) items)")
        } else {
            appLogger.debug("Restored empty clipboard")
        }
    }
    
    /// Get text from clipboard
    /// - Returns: String content if available
    func getClipboardText() -> String? {
        return pasteboard.string(forType: .string)
    }
    
    /// Set clipboard to the given text
    /// - Parameter text: Text to copy to clipboard
    func setClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        appLogger.debug("Set clipboard text (\(text.count) chars)")
    }
    
    /// Check if clipboard has changed since a snapshot
    /// - Parameter snapshot: Previous snapshot to compare against
    /// - Returns: True if clipboard has been modified
    func hasClipboardChanged(since snapshot: ClipboardSnapshot) -> Bool {
        return pasteboard.changeCount != snapshot.changeCount
    }
}
