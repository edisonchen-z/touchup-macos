# TouchUp

TouchUp is a macOS menu bar app that instantly polishes your writing using a local LLM, right where you type.

Select any text in any app, press a hotkey, and TouchUp refines your grammar, clarity, and tone in place. No copy-pasting into a chatbot. No cloud. No cost.

> **Note:** This repository is the macOS-only version of TouchUp. Support for other platforms will live in separate, dedicated repositories.

## Why TouchUp?

Most AI writing tools send your text to the cloud. TouchUp takes a different approach:

- **Local only** — Your text never leaves your machine. All inference runs on-device through [Ollama](https://ollama.com/).
- **No API cost** — No API keys, no subscriptions, no token usage fees.
- **Private by design** — No data collection, no telemetry, no network calls.

TouchUp is part of a broader effort to build a **local LLM ecosystem** — practical, everyday tools powered entirely by models running on your own hardware.

## How It Works

1. Type text in any application (Notes, Mail, Slack, VS Code, etc.).
2. Select the text you want to refine.
3. Press the hotkey (default: `⌘ ⌥ T`).
4. TouchUp sends the text to your local Ollama model, then replaces it in place with the polished version.

## Features

- **Works everywhere** — Any app that supports standard text selection.
- **Configurable hotkey** — Set your preferred trigger shortcut.
- **Model selection** — Use any Ollama-compatible model. Recommended: `gemma2:9b` or `llama3.1:8b`.
- **Custom prompts** — Tailor the polishing instructions to your style.
- **Advanced tuning** — Configure context length, keep-alive duration, and dynamic token prediction.

## Requirements

- **macOS** (built with SwiftUI, runs natively)
- **[Ollama](https://ollama.com/)** installed and running locally

## Installation

### 1. Install Ollama (Required)

TouchUp uses Ollama as its LLM backend. This is a **hard dependency** — the app will not function without it.

1. Download and install Ollama from [ollama.com](https://ollama.com/).
2. Pull a model. For best results, use a model with sufficient parameters:

   ```bash
   ollama run gemma2:9b
   ```

   Models like `gemma2:9b` and `llama3.1:8b` offer a good balance of quality and speed. Smaller models (1B–3B) work but may produce lower-quality results. Browse all available models at [ollama.com/library](https://ollama.com/library).

### 2. Install TouchUp

#### Option A: Download from GitHub Releases (Recommended)

1. Go to the [**Releases**](../../releases) page.
2. Download the latest `.zip` asset (kept in sync with the `main` branch).
3. Unzip and move `TouchUp.app` to your Applications folder.
4. On first launch, **grant Accessibility permissions** when prompted — this is required for TouchUp to read and replace selected text.
5. If macOS blocks the app (unidentified developer), right-click the app and choose **Open**, or run:

   ```bash
   xattr -dr com.apple.quarantine /Applications/TouchUp.app
   ```

#### Option B: Build from Source

1. Clone this repository
2. Open `TouchUp.xcodeproj` in Xcode.
3. Build and run (`⌘R`).
4. Grant Accessibility permissions when prompted.

## Permissions

TouchUp requires **Accessibility access** to read selected text and write the refined text back. macOS will prompt you to grant this on first use. You can manage it anytime in:

**System Settings → Privacy & Security → Accessibility**

## Latency

Tested on **Apple M3 Max** with `gemma2:9b` — input: **284 characters**.

| Scenario | Ollama Latency |
|---|---|
| Cold start (model not loaded) | 2782ms |
| Warm (model already loaded) | 1580ms |

The warm model is **~43% faster** on Ollama inference thanks to `keep_alive` (default: 60 minutes), which keeps the model in memory between calls.

## License

This project is licensed under the [MIT License](LICENSE).
