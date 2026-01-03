import Foundation
import MatomoTracker

// MARK: - Analytics Service

/// Centralized analytics service using Matomo
///
/// ## North Star Metric: Photos Exported
/// This is the core value metric - when a user exports, they've received value from the app.
///
/// ## Key Supporting Metrics:
/// - Activation: First import → First export
/// - Engagement: Edit sessions, filter applications
/// - Retention: Return sessions, photos edited over time
///
/// ## Event Taxonomy Structure:
/// - Category: High-level area (app, photo, editor, filter, tool, export)
/// - Action: What happened (apply, save, export, error)
/// - Name: Specific detail (filter name, tool name, error type)
/// - Value: Numeric value (intensity, count, duration)
@MainActor
final class Analytics {

    // MARK: - Singleton

    static let shared = Analytics()

    // MARK: - Configuration

    private static let matomoURL = URL(string: "https://motomo.roxenberg.dev/matomo.php")!
    private static let siteID = "2"

    // MARK: - Properties

    private var tracker: MatomoTracker?
    private var sessionStartTime: Date?
    private var editorOpenTime: Date?
    private var isEnabled: Bool = true

    // MARK: - User Journey State (for funnel tracking)

    private var hasImportedPhoto: Bool {
        UserDefaults.standard.bool(forKey: "analytics_has_imported")
    }

    private var hasExportedPhoto: Bool {
        UserDefaults.standard.bool(forKey: "analytics_has_exported")
    }

    private var totalExports: Int {
        get { UserDefaults.standard.integer(forKey: "analytics_total_exports") }
        set { UserDefaults.standard.set(newValue, forKey: "analytics_total_exports") }
    }

    // MARK: - Initialization

    private init() {
        setupTracker()
    }

    private func setupTracker() {
        tracker = MatomoTracker(siteId: Self.siteID, baseURL: Self.matomoURL)

        // Set content base URL for event context
        tracker?.contentBase = URL(string: "https://loopix.app")

        // Log level: use .verbose for debugging, .warning for production
        #if DEBUG
        tracker?.logger = DefaultLogger(minLevel: .verbose)
        #else
        tracker?.logger = DefaultLogger(minLevel: .warning)
        #endif

        // Auto-dispatch every 30 seconds
        tracker?.dispatchInterval = 30

        // Ensure tracking is enabled (isOptedOut is persisted in UserDefaults)
        tracker?.isOptedOut = false

        // Set visitor ID for user tracking
        tracker?.forcedVisitorId = getOrCreateVisitorId()
    }

    // MARK: - Visitor ID Management

    private func getOrCreateVisitorId() -> String {
        let key = "analytics_visitor_id"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        let newId = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased()
        UserDefaults.standard.set(String(newId), forKey: key)
        return String(newId)
    }

    // MARK: - Public API

    /// Enable or disable analytics tracking
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        tracker?.isOptedOut = !enabled
    }

    /// Dispatch all queued events immediately
    func dispatch() {
        tracker?.dispatch()
    }

    // MARK: - User Lifecycle Tracking

    private func markFirstImport() {
        guard !hasImportedPhoto else { return }
        UserDefaults.standard.set(true, forKey: "analytics_has_imported")

        // Track activation milestone
        tracker?.track(
            eventWithCategory: Category.lifecycle.rawValue,
            action: "milestone",
            name: "first_import",
            value: nil
        )
    }

    private func markFirstExport() {
        guard !hasExportedPhoto else { return }
        UserDefaults.standard.set(true, forKey: "analytics_has_exported")

        // Track activation complete - user received core value!
        tracker?.track(
            eventWithCategory: Category.lifecycle.rawValue,
            action: "milestone",
            name: "first_export",
            value: nil
        )

        // Track activation funnel completion
        tracker?.track(
            eventWithCategory: Category.lifecycle.rawValue,
            action: "activation",
            name: "complete",
            value: nil
        )
    }
}

// MARK: - Event Taxonomy

extension Analytics {

    /// Event categories following product analytics best practices
    /// Aligned with North Star (export) and supporting metrics
    enum Category: String {
        // Core funnel
        case lifecycle = "lifecycle"    // Activation, retention milestones
        case photo = "photo"            // Import, select, delete
        case editor = "editor"          // Edit sessions
        case filter = "filter"          // Filter usage (engagement)
        case tool = "tool"              // Tool usage (engagement)
        case export = "export"          // NORTH STAR - value delivered

        // Supporting
        case app = "app"                // App lifecycle
        case settings = "settings"      // Settings changes
        case error = "error"            // Errors for debugging
    }

    /// Structured event actions
    enum Action: String {
        // App lifecycle
        case launch = "launch"
        case background = "background"
        case foreground = "foreground"
        case terminate = "terminate"

        // Photo actions
        case `import` = "import"
        case select = "select"
        case delete = "delete"
        case multiSelect = "multi_select"

        // Editor actions
        case open = "open"
        case save = "save"
        case cancel = "cancel"
        case undo = "undo"
        case redo = "redo"

        // Filter actions
        case apply = "apply"
        case preview = "preview"
        case adjust = "adjust"
        case create = "create"
        case favorite = "favorite"
        case unfavorite = "unfavorite"

        // Tool actions
        case use = "use"
        case reset = "reset"

        // Export actions
        case start = "start"
        case complete = "complete"
        case fail = "fail"

        // Settings
        case change = "change"
        case enable = "enable"
        case disable = "disable"

        // Errors
        case crash = "crash"
        case exception = "exception"
    }
}

// MARK: - Screen Tracking

extension Analytics {

    /// Track screen view
    func trackScreen(_ screenName: String) {
        guard isEnabled else { return }
        tracker?.track(view: [screenName])
    }

    /// Screen names for consistency
    enum Screen: String {
        case home = "home"
        case gallery = "gallery"
        case editor = "editor"
        case filters = "filters"
        case filterDetail = "filter_detail"
        case toolDetail = "tool_detail"
        case crop = "crop"
        case export = "export"
        case settings = "settings"
        case fujiRecipeForm = "fuji_recipe_form"
    }

    func trackScreen(_ screen: Screen) {
        trackScreen(screen.rawValue)
    }
}

// MARK: - App Events

extension Analytics {

    /// Track app launch
    func trackAppLaunch() {
        guard isEnabled else { return }
        sessionStartTime = Date()

        // Track app launch as screen view
        tracker?.track(view: ["app_launch"])

        // Track app version as event
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            tracker?.track(
                eventWithCategory: Category.app.rawValue,
                action: "version",
                name: "\(version)_\(build)",
                value: nil
            )
        }

        // Dispatch immediately on launch
        dispatch()
    }

    /// Track app going to background
    func trackAppBackground() {
        guard isEnabled else { return }

        var sessionDuration: Float? = nil
        if let startTime = sessionStartTime {
            sessionDuration = Float(Date().timeIntervalSince(startTime))
        }

        tracker?.track(
            eventWithCategory: Category.app.rawValue,
            action: Action.background.rawValue,
            name: "session_end",
            value: sessionDuration
        )

        dispatch()
    }

    /// Track app returning to foreground
    func trackAppForeground() {
        guard isEnabled else { return }
        sessionStartTime = Date()

        tracker?.track(
            eventWithCategory: Category.app.rawValue,
            action: Action.foreground.rawValue,
            name: "session_resume",
            value: nil
        )
    }
}

// MARK: - Photo Events (Funnel Step 1)

extension Analytics {

    /// Photo import source
    enum ImportSource: String {
        case photoLibrary = "photo_library"
        case camera = "camera"
        case files = "files"
    }

    /// Track photo import - FUNNEL STEP 1
    /// This is the entry point to the core funnel: Import → Edit → Export
    func trackPhotoImport(source: ImportSource, count: Int) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.photo.rawValue,
            action: Action.import.rawValue,
            name: source.rawValue,
            value: Float(count)
        )

        // Mark first import milestone for activation tracking
        markFirstImport()
    }

    /// Track photo selection (entering edit flow)
    func trackPhotoSelect(count: Int = 1) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.photo.rawValue,
            action: count > 1 ? Action.multiSelect.rawValue : Action.select.rawValue,
            name: "photo_selected",
            value: Float(count)
        )
    }

    /// Track photo deletion
    func trackPhotoDelete(count: Int) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.photo.rawValue,
            action: Action.delete.rawValue,
            name: "photo_deleted",
            value: Float(count)
        )
    }
}

// MARK: - Editor Events (Funnel Step 2)

extension Analytics {

    /// Track editor open - FUNNEL STEP 2
    /// User is engaging with core product functionality
    func trackEditorOpen() {
        guard isEnabled else { return }
        editorOpenTime = Date()

        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: Action.open.rawValue,
            name: "editor_opened",
            value: nil
        )
    }

    /// Track editor save - leads to export (North Star)
    func trackEditorSave(hasFilter: Bool, hasToolAdjustments: Bool) {
        guard isEnabled else { return }

        var editType = "original"
        if hasFilter && hasToolAdjustments {
            editType = "filter_and_tools"
        } else if hasFilter {
            editType = "filter_only"
        } else if hasToolAdjustments {
            editType = "tools_only"
        }

        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: Action.save.rawValue,
            name: editType,
            value: nil
        )

        // Track time spent editing (engagement metric)
        if let openTime = editorOpenTime {
            let duration = Float(Date().timeIntervalSince(openTime))
            tracker?.track(
                eventWithCategory: Category.editor.rawValue,
                action: "session_duration",
                name: editType,
                value: duration
            )
        }
        editorOpenTime = nil
    }

    /// Track editor cancel - funnel drop-off point
    func trackEditorCancel(hadChanges: Bool) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: Action.cancel.rawValue,
            name: hadChanges ? "discarded_changes" : "no_changes",
            value: nil
        )

        // Track time spent before abandoning
        if let openTime = editorOpenTime, hadChanges {
            let duration = Float(Date().timeIntervalSince(openTime))
            tracker?.track(
                eventWithCategory: Category.editor.rawValue,
                action: "abandoned_after",
                name: "seconds",
                value: duration
            )
        }
        editorOpenTime = nil
    }

    /// Track undo - indicates user experimentation (good engagement)
    func trackUndo() {
        guard isEnabled else { return }
        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: Action.undo.rawValue,
            name: "undo",
            value: nil
        )
    }

    func trackRedo() {
        guard isEnabled else { return }
        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: Action.redo.rawValue,
            name: "redo",
            value: nil
        )
    }

    /// Track tab switch in editor
    func trackEditorTabSwitch(tab: String) {
        guard isEnabled else { return }
        tracker?.track(
            eventWithCategory: Category.editor.rawValue,
            action: "tab_switch",
            name: tab.lowercased(),
            value: nil
        )
    }
}

// MARK: - Filter Events

extension Analytics {

    /// Track filter application
    func trackFilterApply(filterName: String, category: String, intensity: Float) {
        guard isEnabled else { return }

        // Track the filter apply event
        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: Action.apply.rawValue,
            name: filterName,
            value: intensity
        )

        // Also track category usage
        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: "category_used",
            name: category,
            value: nil
        )
    }

    /// Track filter preview (browsing without applying)
    func trackFilterPreview(filterName: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: Action.preview.rawValue,
            name: filterName,
            value: nil
        )
    }

    /// Track filter intensity adjustment
    func trackFilterIntensityAdjust(filterName: String, intensity: Float) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: Action.adjust.rawValue,
            name: filterName,
            value: intensity
        )
    }

    /// Track filter creation (user-created filter)
    func trackFilterCreate(name: String, source: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: Action.create.rawValue,
            name: source, // e.g., "fuji_recipe", "manual"
            value: nil
        )
    }

    /// Track filter favorite/unfavorite
    func trackFilterFavorite(filterName: String, isFavorite: Bool) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: isFavorite ? Action.favorite.rawValue : Action.unfavorite.rawValue,
            name: filterName,
            value: nil
        )
    }

    /// Track filter category switch
    func trackFilterCategorySwitch(category: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.filter.rawValue,
            action: "category_view",
            name: category,
            value: nil
        )
    }
}

// MARK: - Tool Events

extension Analytics {

    /// Tool types for tracking
    enum ToolType: String {
        // Light
        case exposure = "exposure"
        case contrast = "contrast"
        case highlights = "highlights"
        case shadows = "shadows"
        case whites = "whites"
        case blacks = "blacks"

        // Color
        case temperature = "temperature"
        case tint = "tint"
        case saturation = "saturation"
        case vibrance = "vibrance"

        // Effects
        case clarity = "clarity"
        case sharpness = "sharpness"
        case grain = "grain"
        case vignette = "vignette"
        case fade = "fade"
        case bloom = "bloom"
        case halation = "halation"

        // Other
        case hsl = "hsl"
        case toneCurve = "tone_curve"
        case splitTone = "split_tone"
        case crop = "crop"
        case rotate = "rotate"
    }

    /// Track tool usage
    func trackToolUse(tool: ToolType, value: Float) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.tool.rawValue,
            action: Action.use.rawValue,
            name: tool.rawValue,
            value: value
        )
    }

    /// Track tool use by name
    func trackToolUse(toolName: String, value: Float) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.tool.rawValue,
            action: Action.use.rawValue,
            name: toolName.lowercased(),
            value: value
        )
    }

    /// Track tool reset
    func trackToolReset(tool: ToolType) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.tool.rawValue,
            action: Action.reset.rawValue,
            name: tool.rawValue,
            value: nil
        )
    }

    /// Track tool category switch
    func trackToolCategorySwitch(category: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.tool.rawValue,
            action: "category_view",
            name: category.lowercased(),
            value: nil
        )
    }
}

// MARK: - Export Events (NORTH STAR)

extension Analytics {

    /// Track export start
    /// Part of North Star funnel - user intends to get value
    func trackExportStart(photoCount: Int, format: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.export.rawValue,
            action: Action.start.rawValue,
            name: format,
            value: Float(photoCount)
        )
    }

    /// Track export complete - NORTH STAR METRIC
    /// This is THE key metric - user received value from the app
    func trackExportComplete(photoCount: Int, successCount: Int, format: String, durationSeconds: Float) {
        guard isEnabled else { return }

        // NORTH STAR: Track each successful export
        tracker?.track(
            eventWithCategory: Category.export.rawValue,
            action: Action.complete.rawValue,
            name: format,
            value: Float(successCount)
        )

        // Update lifetime exports and check for first export milestone
        totalExports += successCount
        if successCount > 0 {
            markFirstExport()
        }

        // Track cumulative exports for power user identification
        tracker?.track(
            eventWithCategory: Category.export.rawValue,
            action: "lifetime_total",
            name: "cumulative",
            value: Float(totalExports)
        )

        // Track success rate for quality monitoring
        if photoCount > 0 {
            let successRate = Float(successCount) / Float(photoCount) * 100
            tracker?.track(
                eventWithCategory: Category.export.rawValue,
                action: "success_rate",
                name: format,
                value: successRate
            )
        }

        // Track processing performance
        if durationSeconds > 0 && successCount > 0 {
            let avgTimePerPhoto = durationSeconds / Float(successCount)
            tracker?.track(
                eventWithCategory: Category.export.rawValue,
                action: "avg_time_per_photo",
                name: format,
                value: avgTimePerPhoto
            )
        }
    }

    /// Track export with edit details - enriched North Star event
    func trackExportWithDetails(
        photoCount: Int,
        hasFilter: Bool,
        hasToolEdits: Bool,
        format: String
    ) {
        guard isEnabled else { return }

        var editType = "original"
        if hasFilter && hasToolEdits {
            editType = "filter_and_tools"
        } else if hasFilter {
            editType = "filter_only"
        } else if hasToolEdits {
            editType = "tools_only"
        }

        tracker?.track(
            eventWithCategory: Category.export.rawValue,
            action: "export_type",
            name: editType,
            value: Float(photoCount)
        )
    }

    /// Track export failure - monitors funnel drop-off
    func trackExportFail(reason: String, photoCount: Int = 1) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.export.rawValue,
            action: Action.fail.rawValue,
            name: reason,
            value: Float(photoCount)
        )

        // Track as error for debugging
        tracker?.track(
            eventWithCategory: Category.error.rawValue,
            action: "export_failure",
            name: reason,
            value: nil
        )
    }
}

// MARK: - Settings Events

extension Analytics {

    /// Track setting change
    func trackSettingChange(setting: String, value: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.settings.rawValue,
            action: Action.change.rawValue,
            name: setting,
            value: nil
        )
    }

    /// Track feature toggle
    func trackFeatureToggle(feature: String, enabled: Bool) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.settings.rawValue,
            action: enabled ? Action.enable.rawValue : Action.disable.rawValue,
            name: feature,
            value: nil
        )
    }

    /// Track iCloud backup
    func trackCloudBackup(action: String, success: Bool) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.settings.rawValue,
            action: action,
            name: success ? "success" : "failure",
            value: nil
        )
    }

    /// Track cache clear
    func trackCacheClear(type: String, sizeCleared: Int) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.settings.rawValue,
            action: "cache_clear",
            name: type,
            value: Float(sizeCleared)
        )
    }
}

// MARK: - Error Events

extension Analytics {

    /// Track error
    func trackError(domain: String, code: Int, description: String) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: Category.error.rawValue,
            action: Action.exception.rawValue,
            name: "\(domain)_\(code)",
            value: nil
        )
    }

    /// Track generic error with context
    func trackError(_ error: Error, context: String) {
        guard isEnabled else { return }

        let nsError = error as NSError
        tracker?.track(
            eventWithCategory: Category.error.rawValue,
            action: context,
            name: "\(nsError.domain)_\(nsError.code)",
            value: nil
        )
    }
}

// MARK: - Convenience Extensions

extension Analytics {

    /// Track a generic custom event
    func trackEvent(category: Category, action: Action, name: String, value: Float? = nil) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: category.rawValue,
            action: action.rawValue,
            name: name,
            value: value
        )
    }

    /// Track a custom event with string action
    func trackEvent(category: Category, action: String, name: String, value: Float? = nil) {
        guard isEnabled else { return }

        tracker?.track(
            eventWithCategory: category.rawValue,
            action: action,
            name: name,
            value: value
        )
    }
}
