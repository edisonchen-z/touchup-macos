# logging

## Init logger
import os

let appLogger = Logger(
    subsystem: "com.touchup",
    category: "app"
)

## Log message

appLogger.debug("ContentView init -- logger")


## View logs:
1. Xcode debug area
2. Terminal

log stream --style compact --info --debug --predicate 'subsystem == "com.touchup"'

