//
//  ContentView.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import SwiftUI
import os

struct ContentView: View {
    init() {
        appLogger.debug("ContentView init()")
    }
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
