//
//  SettingsManager.swift
//  TouchUp
//
//  Created by Edison Chen on 12/29/25.
//

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
    private let defaultModel = "gemma2:9b"
    
    // MARK: - Initialization
    
    private init() {
        // Load saved model or use default
        self.selectedModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? defaultModel
    }
    
    // MARK: - Methods
    
    /// Save the selected model to UserDefaults
    private func saveSelectedModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: selectedModelKey)
        appLogger.info("Selected model saved: \(model)")
    }
    
    /// Get the currently selected model
    func getSelectedModel() -> String {
        return selectedModel
    }
    
    /// Reset to default model
    func resetToDefault() {
        selectedModel = defaultModel
    }
}
