# Core Business Logic

## Executive Summary

FilmBox is built on three foundational principles:
1. **Scientific Accuracy** - Film emulation based on measured densitometry data
2. **Performance Excellence** - Sub-200ms processing through GPU acceleration
3. **Community Value** - Recipe sharing ecosystem for sustainable growth

---

## Business Model

### Revenue Streams

```
┌─────────────────────────────────────────────────────────────┐
│                    REVENUE MODEL                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  FREE TIER                    PRO SUBSCRIPTION ($4.99/mo)   │
│  ├─ 5 built-in filters       ├─ All 50+ film emulations    │
│  ├─ Basic adjustments        ├─ Custom filter creation     │
│  ├─ Single photo export      ├─ Batch export (unlimited)   │
│  ├─ Community recipes (view) ├─ ColorChecker calibration   │
│  └─ Watermarked exports      ├─ Recipe sharing (create)    │
│                              ├─ No watermarks               │
│                              ├─ Priority rendering          │
│                              └─ RAW file support            │
│                                                              │
│  LIFETIME LICENSE ($39.99)                                  │
│  └─ All Pro features, forever                               │
│                                                              │
│  FILTER PACKS (one-time $2.99-$9.99)                       │
│  ├─ Cinema Pack (Kodak Vision series)                       │
│  ├─ Vintage Pack (Kodachrome, Autochrome)                   │
│  └─ B&W Master Pack (all monochrome stocks)                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Business Decisions

#### 1. Why Subscription Over One-Time Purchase?

**Decision**: Hybrid model (subscription + lifetime + packs)

**Rationale**:
- Continuous film stock research requires ongoing investment
- Community infrastructure (recipe sharing) has operational costs
- Lifetime option captures users who prefer ownership
- Filter packs allow sampling before committing

**Metrics to Track**:
- Conversion rate: Free → Pro (target: 3%)
- Lifetime vs subscription ratio (target: 30/70)
- Churn rate (target: <5% monthly)

#### 2. Why Scientific Approach Over Artistic?

**Decision**: Measure real film, don't approximate it

**Rationale**:
- Differentiation from VSCO, Lightroom presets (artistic interpretation)
- Defensible IP through documented methodology
- Appeals to professional/technical audience
- Higher perceived value justifies premium pricing

**Implementation**:
- Partner with film labs for densitometry data
- Document methodology publicly for credibility
- Publish comparison studies vs real scans

#### 3. Why Focus on Fuji Recipes?

**Decision**: Build dedicated Fuji X recipe ecosystem

**Rationale**:
- Fuji X community is highly engaged (250K+ r/fujifilm)
- Existing demand for recipe sharing (fujirecipe.com traffic)
- Technical users value accuracy → aligns with scientific positioning
- Creates network effects through sharing

**Implementation**:
- Import Fuji recipe parameters directly
- Export to Fuji camera settings
- Recipe discovery with ratings and tags

---

## Technical Architecture Decisions

### 1. Linear Color Space Processing

**Decision**: All processing in Linear sRGB, output in sRGB

**Business Impact**:
- Physically accurate blending operations
- Consistent results across different source images
- Matches how real film responds to light

```swift
// CRITICAL: This is non-negotiable for accuracy
let context = CIContext(options: [
    .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
])
```

### 2. Actor-Based Concurrency

**Decision**: FilterEngine and ThumbnailCache as Swift actors

**Business Impact**:
- Thread-safe by design (no race conditions)
- Predictable memory usage
- Scales with device capabilities

### 3. WebP Thumbnail Cache

**Decision**: 512px WebP thumbnails with LRU eviction

**Business Impact**:
- 40-60% smaller than JPEG at same quality
- Faster scroll performance in gallery
- Controlled storage footprint (<500MB)

### 4. Metal for Custom Effects

**Decision**: Custom Metal kernels for grain, halation, bloom

**Business Impact**:
- 10-50x faster than CPU equivalents
- Unique effects not possible with CIFilter alone
- Competitive moat through performance

---

## Data Architecture

### Filter Preset Storage

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA STORAGE                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  LOCAL (Device)                                             │
│  ├─ UserDefaults: App settings, preferences                 │
│  ├─ FileManager/Documents: User-created presets             │
│  ├─ FileManager/Caches: Thumbnail cache (WebP)              │
│  └─ Core Data: Edit history, favorites                      │
│                                                              │
│  BUNDLED (App)                                              │
│  └─ BuiltInFilters.json: Factory film presets               │
│                                                              │
│  CLOUD (Future - CloudKit)                                  │
│  ├─ Shared recipes (public database)                        │
│  ├─ User's recipes (private database)                       │
│  └─ Sync across devices                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Recipe Sharing Schema

```swift
struct SharedRecipe: Codable {
    let id: UUID
    let authorId: String
    let name: String
    let description: String
    let parameters: FilterParameters
    let tags: [String]           // ["portrait", "warm", "kodak-like"]
    let filmStock: String?       // Original film this emulates
    let sampleImageURLs: [URL]   // Before/after examples
    let downloadCount: Int
    let rating: Float            // 1-5 stars
    let createdAt: Date
    let compatibility: [String]  // ["fuji-x", "universal"]
}
```

---

## Critical Business Rules

### Rule 1: Filter Processing Order is Fixed

The order of filter application is scientifically determined and must not change:

1. Exposure & Contrast (scene-referred)
2. Tone Curve (characteristic curve)
3. Highlights & Shadows recovery
4. White Balance (light source)
5. HSL Adjustments (per-channel)
6. Saturation & Vibrance (perceptual)
7. Split Tone (color grading)
8. Clarity (local contrast)
9. Sharpening (acutance)
10. Effects (grain, vignette, fade, bloom, halation)

**Rationale**: Matches physical light → film → print chain

### Rule 2: Non-Destructive Editing

All edits are stored as parameters, never baked into pixels until export.

**Implementation**:
- FilterParameters struct captures complete state
- CIImage pipeline is reconstructed on each preview
- Original PHAsset is never modified

### Rule 3: Export Quality Preservation

Export quality must match or exceed source quality.

**Implementation**:
- Default to source resolution
- HEIC format preserves 10-bit color when available
- EXIF metadata preserved by default
- No lossy operations in export chain

---

## Risk Analysis

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Metal kernel incompatibility | Low | High | Fallback to CIFilter equivalents |
| Memory pressure on older devices | Medium | Medium | Aggressive cache eviction, lower preview quality |
| iOS version deprecation | Low | Medium | Abstract Core Image usage behind protocols |

### Business Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Apple launches competing feature | Medium | High | Focus on community, not just filters |
| VSCO/Lightroom copy features | High | Medium | Patent key algorithms, move faster |
| Film manufacturer partnership rejection | Medium | Low | Use public densitometry data, crowdsource |

### Legal Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Film brand trademark issues | Medium | Medium | Use descriptive names ("Porta-style" not "Portra") |
| User-generated content moderation | Low | Low | Community guidelines, report system |

---

## Success Metrics

### Product Metrics

| Metric | Target (Y1) | Target (Y2) |
|--------|-------------|-------------|
| Daily Active Users | 10,000 | 50,000 |
| Photos Processed/Day | 100,000 | 1,000,000 |
| Avg Session Duration | 8 min | 12 min |
| Recipes Created | 5,000 | 50,000 |
| Recipes Shared | 10,000 | 200,000 |

### Financial Metrics

| Metric | Target (Y1) | Target (Y2) |
|--------|-------------|-------------|
| Monthly Recurring Revenue | $50,000 | $200,000 |
| Customer Acquisition Cost | $2.00 | $1.50 |
| Lifetime Value (Pro) | $24.00 | $36.00 |
| LTV:CAC Ratio | 12:1 | 24:1 |

### Quality Metrics

| Metric | Target |
|--------|--------|
| App Store Rating | 4.8+ |
| Crash-Free Sessions | 99.9% |
| Filter Accuracy Score | >95% |
| Support Response Time | <24h |

---

*Last updated: January 2026*
