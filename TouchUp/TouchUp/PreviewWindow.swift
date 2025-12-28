//
//  PreviewWindow.swift
//  TouchUp
//
//  Created by Edison Chen on 12/26/25.
//

import SwiftUI

/// SwiftUI view for the text preview window
/// Shows original and polished text side-by-side with Accept/Reject buttons
struct PreviewWindow: View {
    let originalText: String
    let polishedText: String
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Text Preview")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Original text section
            VStack(alignment: .leading, spacing: 6) {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(originalText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .frame(height: 100)
            }
            
            // Polished text section
            VStack(alignment: .leading, spacing: 6) {
                Text("Polished")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(polishedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .frame(height: 100)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Reject")
                        .frame(minWidth: 80)
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.large)
                
                Spacer()
                
                Button(action: onAccept) {
                    Text("Accept")
                        .frame(minWidth: 80)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(20)
        .frame(width: 450)
    }
}

// MARK: - Preview

#Preview {
    PreviewWindow(
        originalText: "This is some orignal text that has a speling error and could use some polishing.",
        polishedText: "This is some original text that has a spelling error and could use some polishing.",
        onAccept: { print("Accepted") },
        onReject: { print("Rejected") }
    )
}
