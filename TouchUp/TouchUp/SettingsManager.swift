//
//  SettingsManager.swift
//  TouchUp
//
//  Created by Edison Chen on 12/29/25.
//

import Cocoa
import Foundation
import os
import Combine

/// Centralized settings management using UserDefaults
class SettingsManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    
    @Published var selectedModel: String {
        didSet {
            saveSelectedModel(selectedModel)
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private let selectedModelKey = "selectedOllamaModel"
    private let hotkeyKeyCodeKey = "hotkeyKeyCode"
    private let hotkeyModifiersKey = "hotkeyModifiers"
    
    // Default: Cmd + Option + T (17)
    private let defaultModel = "gemma2:9b"
    private let defaultKeyCode = 17
    private let defaultModifiers = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    
    // MARK: - Initialization
    
    private init() {
        // Load saved model or use default
        self.selectedModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? defaultModel
        
        // Load hotkey or use default
        self.hotkeyKeyCode = UserDefaults.standard.object(forKey: hotkeyKeyCodeKey) as? Int ?? defaultKeyCode
        self.hotkeyModifiers = UserDefaults.standard.object(forKey: hotkeyModifiersKey) as? UInt ?? defaultModifiers
    }
    
    // MARK: - Hotkey Properties
    
    @Published private(set) var hotkeyKeyCode: Int
    @Published private(set) var hotkeyModifiers: UInt
    
    /// Human readable hotkey string
    var hotkeyString: String {
        let flags = NSEvent.ModifierFlags(rawValue: hotkeyModifiers)
        var string = ""
        
        if flags.contains(.control) { string += "⌃ " }
        if flags.contains(.option) { string += "⌥ " }
        if flags.contains(.shift) { string += "⇧ " }
        if flags.contains(.command) { string += "⌘ " }
        
        // Map key code to string (basic mapping)
        if let keyString = keyString(for: hotkeyKeyCode) {
            string += keyString.uppercased()
        } else {
            string += "?"
        }
        
        return string
    }
    
    // MARK: - Methods
    
    /// Save the selected model to UserDefaults
    private func saveSelectedModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: selectedModelKey)
        appLogger.info("Selected model saved: \(model)")
    }
    
    /// Update and save hotkey
    func updateHotkey(keyCode: Int, modifiers: UInt) {
        self.hotkeyKeyCode = keyCode
        self.hotkeyModifiers = modifiers
        
        UserDefaults.standard.set(keyCode, forKey: hotkeyKeyCodeKey)
        UserDefaults.standard.set(modifiers, forKey: hotkeyModifiersKey)
        
        appLogger.info("Hotkey updated: \(self.hotkeyString)")
        
        // Notify observers
        NotificationCenter.default.post(name: Notification.Name("HotkeyChanged"), object: nil)
    }
    
    /// Get the currently selected model
    func getSelectedModel() -> String {
        return selectedModel
    }
    
    /// Reset to default model
    func resetToDefault() {
        selectedModel = defaultModel
    }
    
    // MARK: - Helper
    
    private func keyString(for keyCode: Int) -> String? {
        // Basic mapping for common keys
        // In a real app, use TISInputSource or similar for accurate layout-aware mapping
        // This is a simplified fallback
        
        switch keyCode {
        case 17: return "T"
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        default: return nil // Fallback relying on view to handle or use a library
        }
    }
    
    // Fallback for UCKeyTranslate could be implemented here for better accuracy
}
