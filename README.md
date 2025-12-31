# TouchUp

TouchUp is a macOS app that runs in the background and instantly refines user-selected text via a hotkey.

## Features

* All processing runs locally. No network access required.
* Use any local language model installed through Ollama.
* Set a preferred hotkey to trigger the action.
* Workflow:

  1. Type text in any application (e.g., Notes, Mail, Slack, etc).
  2. Select the text to refine.
  3. Press the hotkey (default: Command + Option + T).
  4. TouchUp refines and updates the selected text in place.

## Requirements & Installation

### 1. Install Ollama (Required)
TouchUp requires Ollama to run local language models.

1. Download and install Ollama from [ollama.com](https://ollama.com/).
2. Pull a model to use. For best results, choose a model with a sufficient number of parameters. During testing, `gemma2:9b` and `llama3.1:8b` showed good performance for polishing text. If system memory is limited, smaller models such as 1B or 3B variants can also be used, but they may have reduced reasoning ability and weaker prompt adherence. A list of models can be found from [ollama.com/library](https://ollama.com/library). Install any model using the command:

   ```bash
   ollama run <model_name>
   ```

### 2. Install TouchUp

You can install TouchUp in one of the following ways:

#### Option A: Build from source (Xcode)
1. Clone this repository.
2. Open `TouchUp.xcodeproj` in Xcode.
3. Build and Run (⌘R).
4. Grant the required Accessibility permissions when prompted (needed to read/write selected text).

#### Option B: Download a prebuilt app
1. Go to the **Releases** page of this repository.
2. Download the latest release asset.
3. Unzip and move `TouchUp.app` to the Applications folder.
4. If macOS blocks the app, right-click the app and choose **Open**, or run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/TouchUp.app
   ```
