# TouchUp Logging Guide

This project uses the Unified Logging System (`os.Logger`) for performance and privacy.

## Initialization

The logger is initialized globally with a specific subsystem and category.

```swift
import os

let appLogger = Logger(
    subsystem: "com.touchup",
    category: "app"
)
```

## Usage

Log messages using the `appLogger` instance.

```swift
// Debug-level log
appLogger.debug("ContentView init -- logger")

// Info-level log
appLogger.info("OllamaClient initialized")

// Error-level log
appLogger.error("Connection failed: \(error.localizedDescription)")
```

## Viewing Logs

### Option 1: Xcode Console
Logs appear in the bottom debug area when running the app from Xcode.

### Option 2: Terminal
You can stream logs from the device/simulator using the `log` command line tool. This is useful for standalone builds.

**Command:**
```bash
log stream --style compact --info --debug --predicate 'subsystem == "com.touchup"'
```

**Breakdown:**
- `--style compact`: Reduces output verbosity.
- `--info --debug`: Includes info and debug level messages (omitted by default).
- `--predicate`: Filters logs to only show those from our app's subsystem.
