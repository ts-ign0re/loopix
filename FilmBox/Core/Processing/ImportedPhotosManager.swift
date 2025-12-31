//
//  ImportedPhotosManager.swift
//  FilmBox
//
//  Manages the collection of user-imported photos
//

import Foundation
import Photos
import SwiftUI

// MARK: - Imported Photo Model

/// Represents a photo imported into the app
struct ImportedPhoto: Identifiable, Hashable, Codable {
    let id: UUID
    let assetIdentifier: String
    let importedAt: Date
    var editedParametersData: Data?

    init(asset: PHAsset) {
        self.id = UUID()
        self.assetIdentifier = asset.localIdentifier
        self.importedAt = Date()
        self.editedParametersData = nil
    }

    init(id: UUID = UUID(), assetIdentifier: String, importedAt: Date = Date(), editedParametersData: Data? = nil) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.importedAt = importedAt
        self.editedParametersData = editedParametersData
    }
}

// MARK: - Imported Photos Manager

/// Manages imported photos with persistence
@Observable
@MainActor
final class ImportedPhotosManager {

    // MARK: - Singleton

    static let shared = ImportedPhotosManager()

    // MARK: - Properties

    /// All imported photos
    private(set) var photos: [ImportedPhoto] = []

    /// Selected photo IDs
    var selectedPhotoIDs: Set<UUID> = []

    /// Whether selection mode is active
    var isSelectionMode: Bool = false

    /// Loading state
    private(set) var isLoading: Bool = false

    // MARK: - Private

    private let userDefaultsKey = "importedPhotos"

    // MARK: - Initialization

    private init() {
        loadFromStorage()
    }

    // MARK: - Public API

    /// Import photos from PHAssets
    func importPhotos(_ assets: [PHAsset]) {
        let newPhotos = assets.map { ImportedPhoto(asset: $0) }

        // Avoid duplicates
        let existingIdentifiers = Set(photos.map { $0.assetIdentifier })
        let uniqueNewPhotos = newPhotos.filter { !existingIdentifiers.contains($0.assetIdentifier) }

        photos.insert(contentsOf: uniqueNewPhotos, at: 0)
        saveToStorage()
    }

    /// Remove photos by IDs
    func removePhotos(_ ids: Set<UUID>) {
        photos.removeAll { ids.contains($0.id) }
        selectedPhotoIDs.subtract(ids)
        saveToStorage()

        if selectedPhotoIDs.isEmpty {
            isSelectionMode = false
        }
    }

    /// Remove selected photos
    func removeSelectedPhotos() {
        removePhotos(selectedPhotoIDs)
    }

    /// Get PHAsset for imported photo
    func getAsset(for photo: ImportedPhoto) -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
        return result.firstObject
    }

    /// Get PHAssets for selected photos
    func getSelectedAssets() -> [PHAsset] {
        let selectedPhotos = photos.filter { selectedPhotoIDs.contains($0.id) }
        let identifiers = selectedPhotos.map { $0.assetIdentifier }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        return result.objects(at: IndexSet(integersIn: 0..<result.count))
    }

    // MARK: - Selection

    /// Toggle selection for a photo
    func toggleSelection(_ photo: ImportedPhoto) {
        if !isSelectionMode {
            isSelectionMode = true
        }

        if selectedPhotoIDs.contains(photo.id) {
            selectedPhotoIDs.remove(photo.id)
            if selectedPhotoIDs.isEmpty {
                isSelectionMode = false
            }
        } else {
            selectedPhotoIDs.insert(photo.id)
        }
    }

    /// Check if photo is selected
    func isSelected(_ photo: ImportedPhoto) -> Bool {
        selectedPhotoIDs.contains(photo.id)
    }

    /// Clear all selections
    func clearSelection() {
        selectedPhotoIDs.removeAll()
        isSelectionMode = false
    }

    /// Select all photos
    func selectAll() {
        isSelectionMode = true
        selectedPhotoIDs = Set(photos.map { $0.id })
    }

    /// Number of selected photos
    var selectedCount: Int {
        selectedPhotoIDs.count
    }

    // MARK: - Persistence

    private func saveToStorage() {
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let savedPhotos = try? JSONDecoder().decode([ImportedPhoto].self, from: data) else {
            return
        }

        // Validate that assets still exist
        let identifiers = savedPhotos.map { $0.assetIdentifier }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let validIdentifiers = Set((0..<result.count).map { result.object(at: $0).localIdentifier })

        photos = savedPhotos.filter { validIdentifiers.contains($0.assetIdentifier) }

        // Re-save if some were removed
        if photos.count != savedPhotos.count {
            saveToStorage()
        }
    }

    /// Update edited parameters for a photo
    func updateEditedParameters(for photoID: UUID, parameters: FilterParameters) {
        guard let index = photos.firstIndex(where: { $0.id == photoID }) else { return }
        photos[index].editedParametersData = try? JSONEncoder().encode(parameters)
        saveToStorage()
    }

    /// Get edited parameters for a photo
    func getEditedParameters(for photoID: UUID) -> FilterParameters? {
        guard let photo = photos.first(where: { $0.id == photoID }),
              let data = photo.editedParametersData else { return nil }
        return try? JSONDecoder().decode(FilterParameters.self, from: data)
    }
}
