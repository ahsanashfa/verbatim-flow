# mac-client

macOS desktop shell for microphone control, hotkeys, and pipeline orchestration.

## Run Native AppCore
```bash
cd "/Users/axton/Documents/DailyWork🌴/Project Files/Code Projects/verbatim-flow/apps/mac-client"
swift run verbatim-flow --mode raw --hotkey ctrl+shift+space
```

The app runs as a menu bar item (`VF`). Use the menu to:
- Pause/resume hotkey listener
- Switch `Raw` and `Format-only` modes
- Open Accessibility and Microphone permission pages

## Build and test
```bash
swift build
swift test
```

## Build app bundle
```bash
cd "/Users/axton/Documents/DailyWork🌴/Project Files/Code Projects/verbatim-flow"
./scripts/build-native-app.sh
open "/Users/axton/Documents/DailyWork🌴/Project Files/Code Projects/verbatim-flow/apps/mac-client/dist/VerbatimFlow.app"
```

## Flags
- `--mode raw|format-only`
- `--hotkey ctrl+shift+space` (supports aliases like `shift+option+space`, `shift+alt+space`)
- `--locale zh-Hans`
- `--require-on-device`
- `--dry-run`
