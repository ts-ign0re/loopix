# FilmBox Monetization Strategy

## Model: Annual Subscription Only

**Price**: $29.99/year

Simple, clear, one option. No decision fatigue.

---

## Free vs Pro Feature Matrix

### Filters

| Feature | Free | Pro |
|---------|------|-----|
| Filters per category | 1 free filter | All filters |
| Preview paid filters | ✅ with watermark | ✅ clean |
| Apply paid filters | ✅ with watermark | ✅ clean |
| Export with paid filter | ❌ button disabled | ✅ |

**Free filters (1 per category)**:
- COOL: TBD
- WARM: TBD
- PRO: TBD
- PORTRAIT: TBD
- URBAN: TBD
- FILM: Portra 400
- B&W: Tri-X 400
- VINTAGE: TBD
- CUSTOM: user-created (free adjustments only)

### Bulk Edit

| Action | Free | Pro |
|--------|------|-----|
| Copy edits (free filter) | ✅ | ✅ |
| Paste edits (free filter) | ✅ | ✅ |
| Copy edits (paid filter) | ✅ | ✅ |
| Paste edits (paid filter) | ❌ shows paywall | ✅ |
| Batch export (free filters) | ✅ | ✅ |
| Batch export (paid filters) | ❌ shows paywall | ✅ |

### Fuji Recipes

| Feature | Free | Pro |
|---------|------|-----|
| Create recipes | ✅ | ✅ |
| Import recipes (QR) | ✅ | ✅ |
| Save recipes | ✅ | ✅ |
| Preview recipe (in editor) | ✅ with watermark | ✅ clean |
| Apply recipe to photo | ✅ with watermark + "Premium" button | ✅ |
| Export with recipe | ❌ blocked | ✅ |
| Share recipe (QR export) | ✅ | ✅ |

### Adjustments

| Feature | Free | Pro |
|---------|------|-----|
| Basic (exposure, contrast, saturation) | ✅ | ✅ |
| Temperature, Tint | ✅ | ✅ |
| Highlights, Shadows | ✅ | ✅ |
| HSL Editor | ✅ | ✅ |
| Curves | ✅ | ✅ |
| Split Tone | ✅ | ✅ |

### Effects

| Feature | Free | Pro |
|---------|------|-----|
| Grain | ✅ | ✅ |
| Vignette | ✅ | ✅ |
| Fade | ✅ | ✅ |
| Clarity | ✅ | ✅ |
| Sharpness | ✅ | ✅ |
| Bloom | ✅ | ✅ |
| Halation | ✅ | ✅ |
| Bokeh (Radial/Linear blur) | ✅ | ✅ |

### Export

| Feature | Free | Pro |
|---------|------|-----|
| Export (no filter / free filter) | ✅ | ✅ |
| Export (paid filter) | ❌ disabled | ✅ |
| Export (Fuji recipe) | ❌ disabled | ✅ |
| Max resolution | Full | Full |
| Formats (HEIC/JPEG/PNG) | ✅ | ✅ |

---

## Watermark Specification

**Design**: App logo centered on photo
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│              [logo]                 │
│             FilmBox                 │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

- Asset: AppIcon from Xcode (or dedicated watermark logo)
- Size: ~80pt width, centered
- Opacity: 40-50% white with subtle shadow
- Position: center of image
- Only appears on:
  - Preview when using paid filter (free user)
  - Preview when using Fuji recipe (free user)

---

## Paywall Triggers

### Soft Paywall (dismissible, shows benefits)

1. **Tap on locked filter** → "Unlock all 30+ film filters"
2. **Tap Apply on Fuji recipe** → "Unlock Fuji recipes"
3. **Paste edits with paid filter** → "This edit uses a Pro filter"

### Hard Block (action prevented)

1. **Export button disabled** when:
   - Current edit uses paid filter
   - Current edit is Fuji recipe
   - Show tooltip: "Pro filter - Subscribe to export"

2. **Apply recipe button locked** → shows lock icon, tap shows paywall

---

## User Flows

### Flow 1: Free User Tries Paid Filter

```
1. User browses filters
2. Taps on "Portra 160" (paid, has 🔒 icon)
3. Filter applies with centered logo watermark
4. User likes it, taps Export
5. Export button disabled → paywall appears
6. After subscribe → watermark removed, export enabled
```

### Flow 2: Free User Applies Fuji Recipe

```
1. User opens Fuji Recipe editor
2. Creates recipe, adjusts sliders
3. Preview shows effect WITH centered logo watermark
4. User taps Save → recipe saved
5. User applies recipe to photo in editor
6. Photo shows with centered logo watermark
7. User taps Export → button disabled, shows paywall
8. After subscribe → watermark removed, export enabled
```

### Flow 3: Free User Bulk Edit

```
1. User edits Photo A with paid filter
2. Copies edits
3. Selects Photo B, taps Paste
4. Paywall appears: "This edit uses a Pro filter"
5. Options: [Subscribe $29.99/year] [Cancel]
```

### Flow 4: Free User Exports with Free Filter

```
1. User applies "Portra 400" (free in FILM category)
2. Edits look great
3. Taps Export → works normally
4. No watermark, full quality
```

---

## UI Implementation

### Filter Grid - Lock Icons

```
┌────────┐ ┌────────┐ ┌────────┐
│        │ │      🔒│ │      🔒│
│ Portra │ │ Portra │ │ Ektar  │
│  400   │ │  160   │ │  100   │
│ (free) │ │        │ │        │
└────────┘ └────────┘ └────────┘
```

### Editor with Paid Filter / Fuji Recipe (Free User)

```
┌─────────────────────────────────────┐
│  ←                          Done    │
├─────────────────────────────────────┤
│                                     │
│         ┌───────────────┐           │
│         │               │           │
│         │    [logo]     │ ← centered watermark
│         │   FilmBox     │           │
│         │               │           │
│         └───────────────┘           │
│                                     │
├─────────────────────────────────────┤
│  🔒 Portra 160                      │
│  [🔒 Export]                        │
└─────────────────────────────────────┘
```

Watermark appears when:
- Paid filter is applied (free user)
- Fuji recipe is applied (free user)

Tap on 🔒 Export → shows paywall

### Export Button States

```
Normal (free filter):
┌─────────────────┐
│    Export ✓     │  ← enabled, yellow
└─────────────────┘

Blocked (paid filter):
┌─────────────────┐
│  🔒 Export      │  ← disabled, gray
└─────────────────┘
Tooltip: "Subscribe to export"
```

---

## Paywall Screen Design

```
┌─────────────────────────────────────┐
│              FilmBox Pro            │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────┐    ┌─────────┐        │
│  │ Before  │ →  │ After   │        │
│  │         │    │         │        │
│  └─────────┘    └─────────┘        │
│                                     │
│  ✓ 30+ authentic film emulations   │
│  ✓ Unlimited Fuji recipes          │
│  ✓ Export without watermark        │
│  ✓ Bulk editing with any filter    │
│  ✓ New filters added regularly     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │   $29.99 / year             │   │
│  │   That's only $2.50/month   │   │
│  │                             │   │
│  │      [Subscribe Now]        │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Restore Purchase]                 │
│                                     │
│  Terms of Use • Privacy Policy      │
└─────────────────────────────────────┘
```

---

## Technical Implementation

### Data Model

```swift
struct FilterPreset {
    // ... existing fields
    var isPro: Bool  // true = requires subscription
}

// Or derive from source:
extension FilterPreset {
    var isPro: Bool {
        switch source {
        case .builtIn:
            return !Self.freeFilterIDs.contains(id)
        case .userCreated:
            return false  // user's own filters are free
        case .fujiRecipe:
            return true   // all recipes require pro
        }
    }
}
```

### Subscription State

```swift
@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()

    var isProUser: Bool = false

    func checkAccess(for filter: FilterPreset) -> AccessLevel {
        if isProUser { return .full }
        if filter.isPro { return .watermarked }
        return .full
    }
}

enum AccessLevel {
    case full           // can preview, apply, export
    case watermarked    // can preview with watermark, no export
    case locked         // can't apply (Fuji recipes)
}
```

### Export Guard

```swift
func exportPhoto() {
    guard canExport() else {
        showPaywall()
        return
    }
    // proceed with export
}

func canExport() -> Bool {
    if SubscriptionManager.shared.isProUser { return true }
    if currentFilter?.isPro == true { return false }
    if currentFujiRecipe != nil { return false }
    return true
}
```

---

## Revenue Projection

**Assumptions**:
- Year 1: 100K downloads
- Conversion rate: 4% (conservative for single high-price option)
- Annual price: $29.99
- Apple's cut: 30% (first year), 15% (subsequent)

**Year 1**:
- 100K × 4% = 4,000 subscribers
- 4,000 × $29.99 × 0.70 = **$83,972**

**Year 2** (with retention):
- New: 150K × 4% = 6,000
- Retained: 4,000 × 60% = 2,400
- Total: 8,400 subscribers
- 8,400 × $29.99 × 0.85 = **$214,129**

**Year 3**:
- ~15,000 subscribers
- **$380,000+**

---

## Launch Checklist

- [ ] Define which 1 filter is free in each category
- [ ] Design watermark asset
- [ ] Implement watermark overlay in preview
- [ ] Add `isPro` flag to FilterPreset
- [ ] Create SubscriptionManager
- [ ] Implement export button state logic
- [ ] Design paywall screen
- [ ] Implement paywall triggers
- [ ] Set up StoreKit 2 / RevenueCat
- [ ] Create App Store Connect subscription product
- [ ] Add restore purchases flow
- [ ] Test sandbox purchases
- [ ] Add analytics for conversion funnel

---

*Last updated: January 2025*
