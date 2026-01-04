import Foundation

// MARK: - Localization Extension

extension String {
    /// Returns the localized version of this string key
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized version with format arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}

// MARK: - Localization Keys

/// Type-safe localization keys
enum L10n {
    // MARK: - Navigation & Tabs
    enum Nav {
        static let home = "nav.home".localized
        static let settings = "nav.settings".localized
        static let filters = "nav.filters".localized
    }

    enum Tab {
        static let library = "tab.library".localized
        static let filters = "tab.filters".localized
        static let `import` = "tab.import".localized
        static let settings = "tab.settings".localized
    }

    // MARK: - Common Actions
    enum Action {
        static let save = "action.save".localized
        static let cancel = "action.cancel".localized
        static let delete = "action.delete".localized
        static let discard = "action.discard".localized
        static let ok = "action.ok".localized
        static let edit = "action.edit".localized
        static let done = "action.done".localized
        static let reset = "action.reset".localized
        static let copyEdits = "action.copy_edits".localized
        static let copied = "action.copied".localized
        static let pasteEdits = "action.paste_edits".localized
    }

    // MARK: - Editor
    enum Editor {
        static let keepEdits = "editor.keep_edits".localized
        static let saveError = "editor.save_error".localized
        static let unknownError = "editor.unknown_error".localized
    }

    // MARK: - Home Screen
    enum Home {
        static let noPhotos = "home.no_photos".localized
        static let tapToAdd = "home.tap_to_add".localized
        static let storageLimit = "home.storage_limit".localized
        static let photoAccess = "home.photo_access".localized
        static let allowAccess = "home.allow_access".localized
        static let openSettings = "home.open_settings".localized

        static func deleteConfirmation(count: Int) -> String {
            "home.delete_confirmation".localized(count, count == 1 ? "" : "s")
        }

        static func storageFull(used: String, limit: String) -> String {
            "home.storage_full".localized(used, limit)
        }
    }

    // MARK: - FAB Menu
    enum Fab {
        static let `import` = "fab.import".localized
        static let filters = "fab.filters".localized
        static let settings = "fab.settings".localized
    }

    // MARK: - Settings
    enum Settings {
        static let storage = "settings.storage".localized
        static let limit = "settings.limit".localized
        static let clearPhotos = "settings.clear_photos".localized
        static let clearPhotosComment = "settings.clear_photos_comment".localized
        static let clearCache = "settings.clear_cache".localized
        static let clearCacheComment = "settings.clear_cache_comment".localized
        static let deleteAllPhotos = "settings.delete_all_photos".localized
        static let clearPhotosMessage = "settings.clear_photos_message".localized
        static let clearCacheMessage = "settings.clear_cache_message".localized

        static let exportDefaults = "settings.export_defaults".localized
        static let format = "settings.format".localized
        static let quality = "settings.quality".localized
        static let size = "settings.size".localized

        static let performance = "settings.performance".localized
        static let previewQuality = "settings.preview_quality".localized
        static let affectsResponsiveness = "settings.affects_responsiveness".localized

        static let security = "settings.security".localized
        static let securityMode = "settings.security_mode".localized
        static let stripMetadata = "settings.strip_metadata".localized
        static let stripMetadataComment = "settings.strip_metadata_comment".localized
        static let removedOnExport = "settings.removed_on_export".localized
        static let gpsLocation = "settings.gps_location".localized
        static let dateTime = "settings.date_time".localized
        static let deviceModel = "settings.device_model".localized
        static let cameraSettings = "settings.camera_settings".localized
        static let softwareAuthor = "settings.software_author".localized
        static let thumbnailsPreviews = "settings.thumbnails_previews".localized
        static let protectedTag = "settings.protected_tag".localized

        static let backup = "settings.backup".localized
        static let status = "settings.status".localized
        static let backupNow = "settings.backup_now".localized
        static let syncing = "settings.syncing".localized
        static let checking = "settings.checking".localized
        static let synced = "settings.synced".localized
        static let unavailable = "settings.unavailable".localized
        static let disabled = "settings.disabled".localized
        static let icloudSignin = "settings.icloud_signin".localized
        static let icloudEnable = "settings.icloud_enable".localized

        static let about = "settings.about".localized
        static let tapToCopy = "settings.tap_to_copy".localized
        static let copiedToClipboard = "settings.copied_to_clipboard".localized

        static func used(size: String, limit: Int) -> String {
            "settings.used".localized(size, limit)
        }

        static func version(ver: String, build: String) -> String {
            "settings.version".localized(ver, build)
        }

        static func lastBackup(time: String, device: String) -> String {
            "settings.last_backup".localized(time, device)
        }

        static func lastBackupNoDevice(time: String) -> String {
            "settings.last_backup_no_device".localized(time)
        }
    }

    // MARK: - Time
    enum Time {
        static let justNow = "time.just_now".localized

        static func minAgo(_ min: Int) -> String {
            "time.min_ago".localized(min)
        }

        static func hrAgo(_ hr: Int) -> String {
            "time.hr_ago".localized(hr)
        }

        static func dayAgo(_ days: Int) -> String {
            (days == 1 ? "time.day_ago" : "time.days_ago").localized(days)
        }
    }

    // MARK: - Filter Categories
    enum Category {
        static let favourites = "category.favourites".localized
        static let my = "category.my".localized
        static let fuji = "category.fuji".localized
        static let filters = "category.filters".localized
        static let cool = "category.cool".localized
        static let warm = "category.warm".localized
        static let pro = "category.pro".localized
        static let portrait = "category.portrait".localized
        static let urban = "category.urban".localized
        static let film = "category.film".localized
        static let bw = "category.bw".localized
        static let vintage = "category.vintage".localized
        static let creative = "category.creative".localized
    }

    // MARK: - Tool Categories
    enum ToolCategory {
        static let all = "tool_category.all".localized
        static let essential = "tool_category.essential".localized
        static let light = "tool_category.light".localized
        static let color = "tool_category.color".localized
        static let effects = "tool_category.effects".localized
    }

    // MARK: - Tools
    enum Tool {
        static let exposure = "tool.exposure".localized
        static let contrast = "tool.contrast".localized
        static let highlights = "tool.highlights".localized
        static let shadows = "tool.shadows".localized
        static let whites = "tool.whites".localized
        static let blacks = "tool.blacks".localized
        static let saturation = "tool.saturation".localized
        static let vibrance = "tool.vibrance".localized
        static let temperature = "tool.temperature".localized
        static let tint = "tool.tint".localized
        static let skinTone = "tool.skin_tone".localized
        static let clarity = "tool.clarity".localized
        static let sharpen = "tool.sharpen".localized
        static let grain = "tool.grain".localized
        static let vignette = "tool.vignette".localized
        static let fade = "tool.fade".localized
        static let bloom = "tool.bloom".localized
        static let halation = "tool.halation".localized
    }

    // MARK: - Filters Management
    enum Filters {
        static let title = "filters.title".localized
        static let filmPresets = "filters.film_presets".localized
    }

    // MARK: - Crop
    enum Crop {
        static let free = "crop.free".localized
        static let square = "crop.square".localized
        static let original = "crop.original".localized
    }

    // MARK: - Fuji Recipe Form
    enum FujiRecipe {
        static let title = "fuji.title".localized
        static let helpTitle = "fuji.help_title".localized
        static let helpIntro = "fuji.help_intro".localized
        static let helpCredit = "fuji.help_credit".localized
        static let helpInstruction = "fuji.help_instruction".localized

        static let name = "fuji.name".localized
        static let recipeName = "fuji.recipe_name".localized
        static let filmSimulation = "fuji.film_simulation".localized
        static let grainEffect = "fuji.grain_effect".localized
        static let colorChrome = "fuji.color_chrome".localized
        static let effect = "fuji.effect".localized
        static let fxBlue = "fuji.fx_blue".localized
        static let whiteBalanceShift = "fuji.wb_shift".localized
        static let red = "fuji.red".localized
        static let blue = "fuji.blue".localized
        static let dynamicRange = "fuji.dynamic_range".localized
        static let tone = "fuji.tone".localized
        static let highlight = "fuji.highlight".localized
        static let shadow = "fuji.shadow".localized
        static let color = "fuji.color".localized
        static let detail = "fuji.detail".localized
        static let sharpness = "fuji.sharpness".localized
        static let noiseReduction = "fuji.noise_reduction".localized
        static let clarity = "fuji.clarity".localized

        static let nameRequired = "fuji.name_required".localized
        static let enterName = "fuji.enter_name".localized

        // Help items
        static let helpFilmSim = "fuji.help.film_sim".localized
        static let helpFilmSimDesc = "fuji.help.film_sim_desc".localized
        static let helpWbShift = "fuji.help.wb_shift".localized
        static let helpWbShiftDesc = "fuji.help.wb_shift_desc".localized
        static let helpDynamicRange = "fuji.help.dynamic_range".localized
        static let helpDynamicRangeDesc = "fuji.help.dynamic_range_desc".localized
        static let helpHighlightShadow = "fuji.help.highlight_shadow".localized
        static let helpHighlightShadowDesc = "fuji.help.highlight_shadow_desc".localized
        static let helpColor = "fuji.help.color".localized
        static let helpColorDesc = "fuji.help.color_desc".localized
        static let helpGrain = "fuji.help.grain".localized
        static let helpGrainDesc = "fuji.help.grain_desc".localized
        static let helpColorChrome = "fuji.help.color_chrome".localized
        static let helpColorChromeDesc = "fuji.help.color_chrome_desc".localized

        // Grain options
        static let grainOff = "fuji.grain.off".localized
        static let grainWeakSmall = "fuji.grain.weak_small".localized
        static let grainWeakLarge = "fuji.grain.weak_large".localized
        static let grainStrongSmall = "fuji.grain.strong_small".localized
        static let grainStrongLarge = "fuji.grain.strong_large".localized
    }

    // MARK: - Export
    enum Export {
        enum Format {
            static let jpeg = "export.format.jpeg".localized
            static let png = "export.format.png".localized
        }

        enum Size {
            static let original = "export.size.original".localized
            static let large = "export.size.large".localized
            static let medium = "export.size.medium".localized
            static let small = "export.size.small".localized
        }
    }

    // MARK: - Preview Quality
    enum Quality {
        static let low = "quality.low".localized
        static let medium = "quality.medium".localized
        static let high = "quality.high".localized
    }
}
