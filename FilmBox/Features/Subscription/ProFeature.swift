//
//  ProFeature.swift
//  FilmBox
//
//  Defines which features require Pro subscription
//

import Foundation

// MARK: - Pro Feature Check

@available(iOS 17.0, *)
enum ProFeature {

    // MARK: - Free Filters

    /// Filter names that are free (case-insensitive matching)
    private static let freeFilterNames: Set<String> = [
        // Film
        "kodak colorplus 200",
        "kodak ektachrome e100",
        // B&W
        "ilford delta 100",
        "ilford delta 3200"
    ]

    /// Categories that are entirely free
    private static let freeCategories: Set<FilterCategory> = [
        .fujiRecipes  // All Fuji film simulations are free
    ]

    // MARK: - Check Methods

    /// Check if a filter is free to use (apply + export)
    static func isFilterFree(_ filter: FilterPreset) -> Bool {
        // User-created filters are always free
        if filter.source != .builtIn {
            return true
        }

        // Fuji Recipes category is free
        if freeCategories.contains(filter.category) {
            return true
        }

        // Check against free filter names
        let normalizedName = filter.name.lowercased().trimmingCharacters(in: .whitespaces)
        return freeFilterNames.contains(normalizedName)
    }

    /// Check if a filter requires Pro for export
    static func requiresProForExport(_ filter: FilterPreset?) -> Bool {
        guard let filter = filter else { return false }
        return !isFilterFree(filter) && !SubscriptionManager.shared.isPro
    }

    /// Check if recipe sharing requires Pro
    static func requiresProForSharing() -> Bool {
        return !SubscriptionManager.shared.isPro
    }

    /// Check if user can export with current filter
    static func canExport(with filter: FilterPreset?) -> Bool {
        // No filter = free
        guard let filter = filter else { return true }

        // Pro users can export anything
        if SubscriptionManager.shared.isPro {
            return true
        }

        // Free users can only export free filters
        return isFilterFree(filter)
    }

    /// Check if user can share recipe
    static func canShareRecipe() -> Bool {
        return SubscriptionManager.shared.isPro
    }
}

// MARK: - FilterPreset Extension

@available(iOS 17.0, *)
extension FilterPreset {

    /// Whether this filter is free to use
    var isFree: Bool {
        ProFeature.isFilterFree(self)
    }

    /// Whether this filter requires Pro for export
    var requiresProForExport: Bool {
        !isFree && !SubscriptionManager.shared.isPro
    }

    /// Whether to show lock icon on this filter
    var showLockIcon: Bool {
        !isFree && !SubscriptionManager.shared.isPro
    }
}
