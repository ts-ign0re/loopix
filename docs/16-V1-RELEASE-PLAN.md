# FilmBox V1 Release Plan

## Overview

Первый релиз FilmBox — минимальный жизнеспособный продукт с фокусом на качественные фильтры и Fuji рецепты.

---

## Monetization (V1)

**Модель**: Годовая подписка $29.99/year

### Free vs Pro

| Функция | Free | Pro |
|---------|------|-----|
| Бесплатные фильтры (см. список) | ✅ | ✅ |
| Платные фильтры | preview + watermark | ✅ |
| Export (free filter) | ✅ | ✅ |
| Export (paid filter) | ❌ | ✅ |
| Все adjustments | ✅ | ✅ |
| Все effects | ✅ | ✅ |
| Fuji рецепты создать/редактировать/сохранить | ✅ | ✅ |
| Fuji рецепты применить | ✅ | ✅ |
| Fuji рецепты export | ✅ | ✅ |
| Fuji рецепты share (QR) | ❌ | ✅ |
| Платные фильтры редактировать | ❌ | ❌ |
| Платные фильтры дублировать | ❌ | ❌ |
| Bulk edit (free filter) | ✅ | ✅ |
| Bulk edit (paid filter) | ❌ paywall | ✅ |

### Watermark

- Лого FilmBox по центру фото
- ~80pt, 40-50% opacity
- Появляется при paid фильтре или Fuji рецепте (free user)

### Paywall Trigger

- Тап на disabled Export button → показать paywall

---

## Core Features (V1)

### 1. Gallery
- [ ] Grid view фото из библиотеки
- [ ] Multi-select для batch export
- [ ] Album picker

### 2. Editor
- [ ] Photo preview с live фильтром
- [ ] Filter strip с категориями
- [ ] Adjustments (exposure, contrast, highlights, shadows, etc.)
- [ ] Effects (grain, vignette, fade, clarity, bloom, halation)
- [ ] HSL editor
- [ ] Curves editor
- [ ] Split tone

### 3. Filters
- [ ] 30+ built-in film emulations
- [ ] Free: Kodak ColorPlus, Ektachrome, Ilford Delta 100/3200, все Fuji sims
- [ ] Lock icon на paid фильтрах
- [ ] Watermark overlay для paid filters (free user)
- [ ] Paid фильтры нельзя редактировать/дублировать (никто)

### 4. Fuji Recipes (единственный способ создать свой пресет)
- [ ] Кнопка "Fuji Recipe" на экране фильтров
- [ ] Recipe editor (film sim, WB shift, DR, tone, grain, etc.)
- [ ] Real-time preview carousel
- [ ] Save/load recipes (free)
- [ ] QR code share (Pro only)

### 5. Export
- [ ] Single photo export
- [ ] Batch export
- [ ] HEIC/JPEG/PNG formats
- [ ] Quality slider
- [ ] Resolution options
- [ ] Export button disabled state + paywall

### 6. Subscription
- [ ] StoreKit 2 integration
- [ ] $29.99/year product
- [ ] Paywall screen
- [ ] Restore purchases
- [ ] Subscription status check

---

## Free Filters

### Бесплатные фильтры
| Category | Filter |
|----------|--------|
| FILM | Kodak ColorPlus 200 |
| FILM | Kodak Ektachrome E100 |
| B&W | Ilford Delta 100 |
| B&W | Ilford Delta 3200 |
| FUJI | Все Fuji Film Simulations (Provia, Velvia, Astia, Classic Chrome, etc.) |

### Fuji Recipes (единственный способ создать свой пресет)
- ✅ Создание, редактирование, сохранение — бесплатно
- ✅ Применение и export — бесплатно
- ❌ Шеринг (QR код) — только Pro

### Платные фильтры (все остальные built-in)
- Preview с watermark для Free users
- Нельзя редактировать (никто, даже Pro)
- Нельзя дублировать
- Export только Pro

---

## Out of Scope (V1)

- ❌ Social features / sharing to Instagram
- ❌ Cloud sync
- ❌ Video editing
- ❌ RAW support
- ❌ Presets marketplace
- ❌ In-app camera
- ❌ Bokeh/blur effect
- ❌ Perspective correction
- ❌ Healing/clone tool

---

## Technical Requirements

### iOS
- Minimum: iOS 17.0
- Swift 6, SwiftUI
- Metal for GPU rendering

### Performance
- Filter preview: <100ms
- Full-res export: <2s
- Gallery scroll: 60fps

### Size
- App bundle: <50MB target
- Test images compressed: <300KB each

---

## Launch Checklist

### Pre-Launch
- [ ] All 30+ filters implemented and tested
- [ ] Fuji recipe editor complete
- [ ] Subscription flow working (sandbox tested)
- [ ] Watermark implementation
- [ ] App Store assets (screenshots, description)
- [ ] Privacy policy
- [ ] Terms of service

### Post-Launch (Week 1)
- [ ] Monitor crash reports
- [ ] Respond to reviews
- [ ] Track conversion rate
- [ ] A/B test paywall (if needed)

---

## Success Metrics (V1)

| Metric | Target |
|--------|--------|
| Downloads (Month 1) | 10,000 |
| App Store Rating | 4.5+ |
| Conversion Rate | 4% |
| Day 1 Retention | 40% |
| Day 7 Retention | 20% |

---

*Last updated: January 2025*
