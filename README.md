# TouchUp

TouchUp is a native macOS application that refines selected text instantly within any application you are typing in.

## Features

* **Local Execution**: All processing runs locally. No data is sent to external services, and no network access is required.
* **Local LLM**: Use any local language model installed through Ollama.
* **Configurable Hotkey**: Configure a preferred keyboard shortcut to trigger the action.
* **Workflow**:

  1. Type text in any application (e.g., Notes, Mail).
  2. Select the text to refine.
  3. Press the configured hotkey (default: Command + Option + T).
  4. TouchUp updates the selected text in place.

## 🛠️ Requirements & Installation

### 1. Install Ollama (Required)
TouchUp requires Ollama to run local language models.

1. Download and install Ollama from [ollama.com](https://ollama.com/).
2. Ensure Ollama is running by starting the service:

   ```bash
   ollama serve
   ```
3. Pull a model to use. Recommended options include `gemma2:9b` or `llama3.1:8b`. If system memory is limited, smaller models such as `llama3.2:3b` or 1b models can be used, though smaller models may have reduced reasoning ability and weaker prompt adherence. Install a model using:

   ```bash
   ollama run gemma2:9b
   ```

### 2. Install TouchUp
1.  Clone this repository.
2.  Open `TouchUp.xcodeproj` in Xcode.
3.  Build and Run (⌘R).
4.  Ensure you grant the necessary Accessibility permissions when prompted (required to read/write selected text).
