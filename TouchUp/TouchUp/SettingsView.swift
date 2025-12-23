//
//  SettingsView.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("TouchUp Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Text("No settings yet")
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 200)
    }
}

#Preview {
    SettingsView()
}
