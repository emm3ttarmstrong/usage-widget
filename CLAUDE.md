# Claude Code Usage Widget

macOS SwiftUI desktop widget showing Claude Code usage as a contribution grid + rate limit bars.

## Build

```bash
make build      # Release build → build/Build/Products/Release/UsageWidget.app
make install    # Build + copy to /Applications
make clean      # Remove build/
make setup BUNDLE_ID=com.you.UsageWidget  # Change bundle ID in all 3 places
```

Or open `UsageWidget/UsageWidget.xcodeproj` in Xcode and hit Cmd+R.

## Project Structure

```
UsageWidget/UsageWidget/
├── App/
│   ├── AppDelegate.swift          # NSPanel setup, menu bar, position persistence, App Nap prevention
│   └── UsageWidgetApp.swift       # @main entry point
├── Models/
│   ├── ContributionDay.swift      # Day model + IntensityLevel enum (message count thresholds)
│   └── StatsCache.swift           # Decodable for ~/.claude/stats-cache.json
├── ViewModels/
│   └── StatsViewModel.swift       # Loads cache, merges live JSONL data, polls API, builds grid
├── Views/
│   ├── ContentView.swift          # Root layout — grid + bars + hover stats row
│   ├── ContributionGraphView.swift # 16-week Mon-Fri grid with month labels
│   ├── ContributionCellView.swift  # Single cell with hover tooltip
│   └── UsageLimitBarView.swift     # Vertical fill bar for rate limits
├── Utilities/
│   ├── FileWatcher.swift          # DispatchSource file monitor on stats-cache.json
│   ├── LiveStatsComputer.swift    # Scans ~/.claude/projects/*/*.jsonl for recent activity
│   └── UsageAPIClient.swift       # Fetches /api/oauth/usage from Anthropic API
├── Info.plist                     # LSUIElement=YES (no dock icon)
├── UsageWidget.entitlements       # Keychain access group + network client
└── Assets.xcassets
```

## Data Flow

1. **Cached history**: `~/.claude/stats-cache.json` — daily message/session counts from claude-code-stats CLI
2. **Live today**: Scans `~/.claude/projects/*/` JSONL transcript files for today's messages (30s refresh)
3. **API rate limits**: `GET https://api.anthropic.com/api/oauth/usage` with OAuth token (60s refresh)
4. **Plan tier**: Reads `~/.claude/.credentials.json` → `claudeAiOauth.rateLimitTier`

## Authentication (Keychain)

The API client reads the OAuth token from the macOS Keychain:
- Keychain service name: `"Claude Code-credentials"`
- Uses `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w` (CLI approach, no entitlements needed)
- Output is hex-encoded → hex decode → parse JSON → extract `accessToken`
- Token is stored by Claude Code's own login flow — no manual setup needed

## Bundle ID

The bundle ID `com.emmett.UsageWidget` appears in exactly 3 places:
1. `UsageWidget.xcodeproj/project.pbxproj` — Debug config (line ~309)
2. `UsageWidget.xcodeproj/project.pbxproj` — Release config (line ~284)
3. `UsageWidget/UsageWidget.entitlements` — keychain-access-groups (line 7)

Change all 3 with: `make setup BUNDLE_ID=com.yourname.UsageWidget`

## Key Details

- **macOS 15.0+** (Sequoia) — `MACOSX_DEPLOYMENT_TARGET = 15.0`
- **Xcode 16.0+** — `LastUpgradeCheck = 1600`
- **Swift 5.0**, no external dependencies, no SPM packages
- **No tests** in the project
- **Window**: NSPanel, borderless, floats above desktop, draggable, position saved to UserDefaults
- **LSUIElement = YES**: App runs as menu bar accessory (no Dock icon)
- **App Nap prevention**: Uses `ProcessInfo.beginActivity(.userInitiated)` to keep timers running
- `project.yml` is gitignored (XcodeGen generated, not checked in)
- `build/` is gitignored (Makefile output directory)
