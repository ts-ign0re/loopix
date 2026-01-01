# Image Storage and Export Architecture

## Overview

FilmBox uses a local-first storage approach where all imported photos are copied to the app's Documents directory. This ensures photos remain available even if the original is deleted from the Photos library.

---

## Directory Structure

```
Documents/
├── ImportedImages/          # Full-resolution images
│   ├── {uuid}.heic
│   └── ...
├── Thumbnails/              # Preview thumbnails
│   ├── {uuid}_thumb.heic
│   └── ...
└── Exports/                 # Temporary export files (cleaned up)
```

---

## Import Flow

### 1. Photo Selection
- User selects photos via `PhotoPickerView` (PHPickerViewController wrapper)
- Selected `PHAsset` objects are passed to `ImportedPhotosManager.importPhotos()`

### 2. Full Image Storage
```swift
// Location: ImportedPhotosManager.swift

// Request full-resolution image data from Photos framework
PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options)

// Convert to HEIC for efficient storage (quality: 0.9)
let heicData = context.heifRepresentation(
    of: ciImage,
    format: .RGBA8,
    colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    options: [kCGImageDestinationLossyCompressionQuality: 0.9]
)

// Save to: Documents/ImportedImages/{uuid}.heic
heicData.write(to: imageURL)
```

### 3. Thumbnail Generation
```swift
// Scale to max 512px (maintaining aspect ratio)
let maxSize: CGFloat = 512
let scale = min(maxSize / ciImage.extent.width, maxSize / ciImage.extent.height, 1.0)
let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

// Save as HEIC (quality: 0.7)
// Location: Documents/Thumbnails/{uuid}_thumb.heic
```

### 4. Metadata Persistence
```swift
// Photo metadata stored in UserDefaults as JSON
struct ImportedPhoto: Codable {
    let id: UUID
    let assetIdentifier: String      // Original PHAsset ID (for reference)
    let importedAt: Date
    var editedParametersData: Data?  // Encoded FilterParameters
    var thumbnailVersion: Int        // Incremented on thumbnail regeneration
}
```

---

## Thumbnail Caching

### In-Memory Cache
```swift
// NSCache with ~100MB limit
private let thumbnailCache = NSCache<NSString, UIImage>()
thumbnailCache.countLimit = 100
thumbnailCache.totalCostLimit = 100 * 1024 * 1024

// Cache key format: "{uuid}_v{thumbnailVersion}"
// Version ensures cache invalidation after edits
```

### Loading Flow
```
1. Check NSCache (memory)
   ↓ miss
2. Load from disk (Documents/Thumbnails/)
   ↓ success
3. Store in NSCache
   ↓
4. Return UIImage
```

---

## Thumbnail Regeneration

When a photo is edited and saved, the thumbnail must be regenerated to reflect the changes:

```swift
// Location: ImportedPhotosManager.regenerateThumbnail(for:)

func regenerateThumbnail(for photoID: UUID) async {
    // 1. Load full-resolution image
    let ciImage = loadCIImage(for: photo)

    // 2. Apply current filter parameters (including crop)
    if let params = getEditedParameters(for: photoID) {
        processedImage = await FilterEngine.shared.apply(params, to: ciImage)
    }

    // 3. Scale to thumbnail size (512px)
    let scale = min(512 / processedImage.extent.width, 512 / processedImage.extent.height, 1.0)
    let scaledImage = processedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    // 4. Save and increment version
    heicData.write(to: thumbnailURL)
    photos[index].thumbnailVersion += 1  // Triggers UI refresh
}
```

---

## Export Flow

### Single/Batch Export
```swift
// Location: MainTabView.swift → exportAndShare()

private func exportAndShare() {
    let photos = manager.getSelectedPhotosForLocalExport()
    var urls: [URL] = []

    for item in photos {
        // 1. Load full-resolution from local storage
        let ciImage = ImportedPhotosManager.shared.loadCIImage(for: item.photo)

        // 2. Apply filter parameters if edited
        var processedImage = ciImage
        if let params = item.parameters {
            processedImage = await FilterEngine.shared.apply(params, to: ciImage)
        }

        // 3. Export to temporary HEIC file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(item.photo.id.uuidString).heic")

        let heicData = context.heifRepresentation(
            of: processedImage,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        )
        heicData.write(to: tempURL)
        urls.append(tempURL)
    }

    // 4. Present iOS Share Sheet
    let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
    // ... present on topmost view controller
}
```

### Export Options (via ExportEngine)
For more advanced export needs, `ExportEngine` provides:
- Format selection: HEIC, JPEG, PNG
- Quality control: 0-100%
- Size constraints: Original, Large (3000px), Medium (2000px), Small (1200px)
- EXIF preservation
- Batch processing with progress callback

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         IMPORT                                   │
│                                                                  │
│  PHAsset ──┬──► HEIC (quality 0.9) ──► Documents/ImportedImages/ │
│            │                                                     │
│            └──► Thumbnail (512px, 0.7) ──► Documents/Thumbnails/ │
│                                                                  │
│            └──► Metadata (JSON) ──► UserDefaults                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DISPLAY                                   │
│                                                                  │
│  Gallery Grid:                                                   │
│    Thumbnail ──► NSCache ──► UIImage ──► SwiftUI Image           │
│                                                                  │
│  Editor Preview:                                                 │
│    Full HEIC ──► CIImage ──► FilterEngine.apply() ──► MTKView    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         EDIT                                     │
│                                                                  │
│  User adjusts ──► FilterParameters ──► Live preview              │
│                                                                  │
│  Save:                                                           │
│    FilterParameters ──► JSON ──► ImportedPhoto.editedParametersData │
│    Thumbnail regenerated with applied filters                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        EXPORT                                    │
│                                                                  │
│  Full HEIC ──► CIImage ──► FilterEngine.apply(params)            │
│            ──► HEIC (temp) ──► UIActivityViewController          │
│                                                                  │
│  User can: Save to Photos, AirDrop, Share to apps, etc.          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Classes

| Class | Responsibility |
|-------|----------------|
| `ImportedPhotosManager` | Photo storage, metadata, thumbnails, selection |
| `FilterEngine` | GPU image processing, filter application |
| `HALDCLUTLoader` | Load and cache film simulation LUTs |
| `ExportEngine` | Batch export with format/quality options |

---

## Storage Limits & Cleanup

- **Thumbnail cache (memory):** ~100MB, LRU eviction
- **Thumbnail cache (disk):** No automatic cleanup
- **Temp exports:** System manages `/tmp` cleanup
- **Deleted photos:** Both full image and thumbnail are removed from disk

```swift
func removePhotos(_ ids: Set<UUID>) {
    for id in ids {
        // Delete local files
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: thumbURL)
    }
    // Update metadata
    saveMetadataToStorage()
}
```
