# Analytics Module

## Overview

Analytics module using [MatomoTracker iOS SDK](https://github.com/matomo-org/matomo-sdk-ios) v7.8.0.

## Configuration

```swift
// Analytics.swift
private static let matomoURL = URL(string: "https://motomo.roxenberg.dev/matomo.php")!
private static let siteID = "2"
```

## Key Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `dispatchInterval` | 30 sec | Auto-dispatch queued events |
| `contentBase` | `https://app.filmbox.io` | Base URL for event context |
| `isOptedOut` | `false` | Must be explicitly set (persisted in UserDefaults) |
| `forcedVisitorId` | 16-char hex | Persisted visitor ID for cross-session tracking |

## Event Taxonomy

### Categories
- `lifecycle` - Activation, retention milestones
- `photo` - Import, select, delete
- `editor` - Edit sessions
- `filter` - Filter usage
- `tool` - Tool adjustments
- `export` - **North Star metric**
- `app` - App lifecycle
- `settings` - Settings changes
- `error` - Error tracking

### North Star Metric: Photos Exported

The core value metric. When a user exports, they've received value from the app.

## Usage

```swift
// App launch
Analytics.shared.trackAppLaunch()

// Screen view
Analytics.shared.trackScreen(.editor)

// Filter applied
Analytics.shared.trackFilterApply(filterName: "Portra 400", category: "film", intensity: 85)

// Export complete (North Star)
Analytics.shared.trackExportComplete(photoCount: 5, successCount: 5, format: "HEIC", durationSeconds: 12.5)
```

## Opt-out

```swift
// Disable tracking (persisted)
Analytics.shared.setEnabled(false)

// Enable tracking
Analytics.shared.setEnabled(true)
```

## Debugging

In DEBUG builds, MatomoTracker logs at `.verbose` level:
```
MatomoTracker [V] Queued event: ...
MatomoTracker [I] Dispatched batch of 3 events.
```

## Troubleshooting

### Events not sending

1. Check `isOptedOut` - SDK persists this in UserDefaults
2. Check `isEnabled` in Analytics wrapper
3. Verify network connectivity
4. Check Matomo server URL and siteID

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Queue empty after track() | `isOptedOut = true` | Set `isOptedOut = false` in setupTracker |
| Events not in dashboard | Wrong siteID | Verify siteID matches Matomo website config |
| 401 on API calls | Wrong auth token | Use read-access token for Reporting API |
