import SwiftUI

/// SwiftUI view for the text preview window
/// Shows original and refined text with visual hierarchy and diff highlighting
struct PreviewWindow: View {
    let originalText: String
    let polishedText: String
    let onAccept: () -> Void
    let onReject: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 28) {
                
                // Original text section - de-emphasized
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Original text section")
                    
                    ScrollView {
                        Text(originalText)
                            .font(.system(size: scaledFontSize(base: 14, geometry: geometry)))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor).opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .frame(minHeight: 80, maxHeight: .infinity)
                }
                
                // Refined text section - emphasized with diff highlighting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Refined text section")
                    
                    ScrollView {
                        // Use diff highlighting if available
                        highlightedRefinedText(geometry: geometry)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .frame(minHeight: 80, maxHeight: .infinity)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Action buttons with keyboard hints
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        HStack(spacing: 4) {
                            Text("Reject")
                            Text("⎋")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 80)
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.borderless) // De-emphasized
                    .controlSize(.large)
                    .help("Reject changes (Esc)")
                    
                    Spacer()
                    
                    Button(action: onAccept) {
                        HStack(spacing: 4) {
                            Text("Accept")
                            Text("⏎")
                                .font(.caption2)
                        }
                        .frame(minWidth: 80)
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .help("Accept changes (Return)")
                }
            }
            .padding(24)
            .frame(minWidth: 400, minHeight: 350)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.2), value: appeared)
            .onAppear {
                appeared = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate scaled font size based on window dimensions
    private func scaledFontSize(base: CGFloat, geometry: GeometryProxy) -> CGFloat {
        // Scale based on width, with a reasonable range
        let widthScale = geometry.size.width / 480 // 480 is the base width
        let cappedScale = min(max(widthScale, 0.8), 2.0) // Limit scaling between 0.8x and 2x
        return base * cappedScale
    }
    
    /// Creates highlighted text showing diff changes
    @ViewBuilder
    private func highlightedRefinedText(geometry: GeometryProxy) -> some View {
        let changes = TextDiffUtility.computeWordDiff(original: originalText, refined: polishedText)
        let fontSize = scaledFontSize(base: 17, geometry: geometry)
        
        if changes.isEmpty {
            // Fallback to plain text
            Text(polishedText)
                .font(.system(size: scaledFontSize(base: 18, geometry: geometry), weight: .semibold))
                .foregroundColor(.primary)
        } else {
            let attributed = TextDiffUtility.createHighlightedText(changes: changes, fontSize: fontSize)
            Text(attributed)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    PreviewWindow(
        originalText: "solution should work but there a few edge cases we didnt think through",
        polishedText: "The solution should work but there are a few edge cases we didn't think through.",
        onAccept: { print("Accepted") },
        onReject: { print("Rejected") }
    )
}
