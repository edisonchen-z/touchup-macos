//
//  SettingsView.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import SwiftUI
import os

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var availableModels: [OllamaModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let ollamaClient = OllamaClient()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TouchUp Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            // Model Selection Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Ollama Model")
                    .font(.headline)
                
                modelSelectionView
            }
            
            Divider()
            
            // Current Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Configuration")
                    .font(.headline)
                
                SettingRow(label: "Hotkey", value: "Cmd + Option + T")
                SettingRow(label: "Selected Model", value: settingsManager.selectedModel)
                SettingRow(label: "Ollama URL", value: "http://localhost:11434")
            }
            
            Divider()
            
            // Future Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("• Custom hotkey configuration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Prompt templates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Requirements")
                    .font(.headline)
                
                Text("1. Ollama must be running: ollama serve")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("2. Model must be installed: ollama pull <model-name>")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("3. Accessibility permission must be granted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            loadModels()
        }
    }
    
    // MARK: - Model Selection View
    
    @ViewBuilder
    private var modelSelectionView: some View {
        if isLoading {
            // Loading State
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading models...")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
        } else if let error = errorMessage {
            // Error State
            errorStateView(error: error)
        } else if availableModels.isEmpty {
            // No Models State
            noModelsStateView
        } else {
            // Success State
            successStateView
        }
    }
    
    @ViewBuilder
    private var successStateView: some View {
        HStack {
            Picker("", selection: $settingsManager.selectedModel) {
                ForEach(availableModels) { model in
                    Text(model.name).tag(model.name)
                }
            }
            .frame(maxWidth: 250)
            
            Button(action: {
                loadModels()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh model list")
        }
    }
    
    @ViewBuilder
    private func errorStateView(error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Cannot connect to Ollama")
                    .font(.headline)
            }
            
            Text("Please ensure Ollama is running to select a model.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                Button("Open Terminal") {
                    openTerminalWithCommand()
                }
                
                Button("Retry") {
                    loadModels()
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var noModelsStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("No models found")
                    .font(.headline)
            }
            
            Text("Please install a model first:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("ollama pull gemma2:9b")
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            
            Button("Copy Command") {
                copyToClipboard("ollama pull gemma2:9b")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Methods
    
    private func loadModels() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let models = try await ollamaClient.listInstalledModels()
                await MainActor.run {
                    self.availableModels = models
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func openTerminalWithCommand() {
        let script = """
        tell application "Terminal"
            activate
            do script "ollama serve"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                appLogger.error("Failed to open Terminal: \(error)")
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// Helper view for settings rows
struct SettingRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.medium)
            Spacer()
        }
        .font(.body)
    }
}

#Preview {
    SettingsView()
}
