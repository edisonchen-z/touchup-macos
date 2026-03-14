import SwiftUI
import os

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var availableModels: [OllamaModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isAdvancedExpanded = false
    @State private var keepAliveText: String = ""
    private let ollamaClient = OllamaClient()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Ollama Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ollama Settings")
                        .font(.headline)
                    
                    Text("Ollama Model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    modelSelectionView
                    
                    Text("Ollama Server Address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    TextField("Server address", text: $settingsManager.ollamaServerAddress)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }
                
                Divider()
                
                // 2. Hotkey Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hotkey")
                        .font(.headline)
                    
                    HStack {
                        Text("Hotkey:")
                            .foregroundColor(.secondary)
                        HotkeyRecorder()
                        Spacer()
                    }
                }
                
                Divider()
                
                // 3. Prompt Strategy Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt Strategy")
                        .font(.headline)
                    
                    Picker("", selection: $settingsManager.customPromptEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use the default prompt")
                            Text("Keeps original tone. Improves only grammar and clarity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }.tag(false)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use a custom prompt")
                            Text("Define your own style and rules")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }.tag(true)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    
                    if settingsManager.customPromptEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Prompt Template:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $settingsManager.customPromptText)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(height: 120)
                                .padding(4)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            
                            Text("Formatting rules (return only revised text) are automatically applied.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                
                Divider()
                
                // 4. Advanced Ollama Settings Section
                DisclosureGroup("Advanced Ollama Settings", isExpanded: $isAdvancedExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Keep Alive:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                            TextField("", text: $keepAliveText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .onChange(of: keepAliveText) { _, newValue in
                                    // Allow empty, "-", "-1", or positive integers
                                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                    if trimmed.isEmpty || trimmed == "-" {
                                        return
                                    }
                                    if let value = Int(trimmed), value == -1 || value >= 1 {
                                        settingsManager.keepAliveMinutes = value
                                    } else {
                                        // Revert to last valid value
                                        keepAliveText = String(settingsManager.keepAliveMinutes)
                                    }
                                }
                            Text("min")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Text("Time a model remains loaded in memory after a request")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Context Length:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: $settingsManager.contextLength) {
                                Text("2048").tag(2048)
                                Text("4096").tag(4096)
                                Text("8192").tag(8192)
                            }
                            .frame(width: 100)
                            Spacer()
                        }
                        
                        Text("Max tokens per request (prompt + response)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Dynamic Token Prediction")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Toggle("", isOn: $settingsManager.dynamicTokenPredictionEnabled)
                                .labelsHidden()
                            Spacer()
                        }
                        
                        Text("Optimize output limit for lower latency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .font(.headline)
                

                
                Spacer()
                
            }
            .padding(30)
        }
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            keepAliveText = String(settingsManager.keepAliveMinutes)
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

struct HotkeyRecorder: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var isRecording = false
    @State private var monitor: Any?
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            if isRecording {
                Text("Press keys...")
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            } else {
                Text(settings.hotkeyString)
                    .fontWeight(.medium)
            }
        }
        .buttonStyle(.bordered)
        .onChange(of: isRecording) { _, recording in
            if recording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }
    
    private func startRecording() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Clean modifiers (remove generic flags like shift/control/alt without side)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Ignore just modifier key presses
            if flags.isEmpty && event.keyCode < 0 {
                return event
            }
            
            // Require at least one modifier + key, or just function keys
            // But usually we want Modifiers + Key
            if !flags.isEmpty {
                 SettingsManager.shared.updateHotkey(
                    keyCode: Int(event.keyCode),
                    modifiers: flags.rawValue
                )
                
                // Stop recording
                isRecording = false
                return nil // Consume event
            }
            
            if event.keyCode == 53 { // ESC
                 isRecording = false
                 return nil
            }
            
            return nil
        }
    }
    
    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

#Preview {
    SettingsView()
}
