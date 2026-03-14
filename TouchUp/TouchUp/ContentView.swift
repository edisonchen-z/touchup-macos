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
