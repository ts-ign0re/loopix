# FilmBox Documentation

Technical documentation for the FilmBox iOS photo editor.

## Contents

| Document | Description |
|----------|-------------|
| [Image Storage and Export](./image-storage-and-export.md) | How photos are stored locally and exported |
| [Filter Engine](./filter-engine.md) | GPU image processing pipeline and filter application |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      SwiftUI Layer                          │
│  MainTabView, EditorView, LibraryContentView                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     Manager Layer                           │
│  ImportedPhotosManager (storage, metadata, thumbnails)      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Processing Layer                          │
│  FilterEngine (actor) ─── HALDCLUTLoader                   │
│  ExportEngine (actor)                                       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Core Image                             │
│  CIContext (GPU) ─── CIFilters ─── Metal Kernels           │
└─────────────────────────────────────────────────────────────┘
```

## Key Technologies

- **SwiftUI** - UI framework
- **Core Image** - GPU image processing
- **Metal** - Custom shader kernels
- **PhotoKit** - Photo library access
- **HEIC** - Efficient image storage format

## File Locations

| Data | Location |
|------|----------|
| Full images | `Documents/ImportedImages/*.heic` |
| Thumbnails | `Documents/Thumbnails/*_thumb.heic` |
| Metadata | `UserDefaults["importedPhotos"]` |
| Film LUTs | `Bundle/Resources/CLUTs/*.png` |
| Temp exports | `tmp/*.heic` |
