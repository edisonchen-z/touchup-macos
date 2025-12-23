//
//  SettingsView.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TouchUp Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            // Current Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Configuration")
                    .font(.headline)
                
                SettingRow(label: "Hotkey", value: "Cmd + Option + T")
                SettingRow(label: "Ollama Model", value: "qwen2.5:3b")
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
                
                Text("• Model selection")
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
                
                Text("2. Model must be installed: ollama pull qwen2.5:3b")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("3. Accessibility permission must be granted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(minWidth: 450, minHeight: 400)
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
