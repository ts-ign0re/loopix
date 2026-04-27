# Loopix — Film Camera for iPhone

Loopix is a professional iOS camera app built around authentic analog film emulation. It combines a real-time GPU-accelerated filter pipeline with physically-based film grain to produce images that look and feel like actual film stock.

[![Download on the App Store](https://img.shields.io/badge/App_Store-Download-black?logo=apple)](https://apps.apple.com/app/id6757521749)

---

## Features

### 28 Film Presets
Color and B&W presets inspired by classic film stocks — Kodak Portra, Fujifilm Velvia, cinematic stocks, and more. Each preset has its own tone curve, color grade, and grain signature.

### Physically-Based Film Grain
Grain is rendered on the GPU via a custom Metal shader that models silver halide crystal development. Three noise layers (Gaussian, Simplex 2D, Worley) combine to produce realistic grain texture. Parameters per preset:

- **Amount** — grain density with a film-like response curve
- **Size** — crystal scale (0.5×–4.0× pixel radius)
- **Roughness** — texture coarseness
- **Clumping** — simulates grain clustering in dense areas
- **Monochromatic** — desaturated grain vs. color noise

Grain animation rate adapts via accelerometer — it slows when the camera is stationary so the image stays readable.

### Adjustable Filter Intensity
Each filter can be blended from 0% (original) to 100% (full effect) in real time using an on-screen dial. Intensity is saved per filter across sessions.

### Multi-Lens Support
Automatically enumerates all available lenses (ultra-wide, wide, telephoto) and lets you switch between them mid-session.

### Full Manual Controls
- **EV compensation**: −3.0 to +3.0 stops via a circular wheel
- **Focus point**: tap anywhere on the frame
- **AE/AF lock**: lock focus and exposure independently
- **Grid overlay**: rule-of-thirds guide

### Capture Modes
- **Photo**: full-resolution HEIC output in P3 color space, filters applied post-capture
- **Video**: live filter preview during recording, filter switching while recording

### Ergonomic Layout
Onboarding asks for handedness. The shutter button repositions for left- or right-handed grip. Can be toggled any time from the main view.

---

## Architecture

### Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI, `@Observable` |
| Camera | AVFoundation |
| Live preview | Metal / MetalKit (`MTKView`) |
| Filter pipeline | CoreImage |
| Grain rendering | Metal compute shaders |
| Motion | CoreMotion |
| Purchases | StoreKit 2 |
| Photos | PHPhotoLibrary |

No third-party dependencies. Pure Swift + Apple frameworks.

### Camera Pipeline

```
AVCaptureSession
    └── AVCaptureVideoDataOutput → MetalPreviewRenderer → MTKView (30fps live preview)
    └── AVCapturePhotoOutput    → PhotoCaptureProcessor → CoreImage pipeline → HEIC → Photos
```

**Live preview**: each frame goes through `MetalPreviewRenderer`, which applies the full filter pipeline via CoreImage and composites real-time grain on top using a Metal shader.

**Photo capture**: `PhotoCaptureProcessor` receives the raw pixel buffer, runs the same CoreImage pipeline at full resolution, adds grain, and saves HEIC at ~0.9 quality to the photo library.

### Filter Pipeline (CoreImage)

Each frame runs through a chained CIFilter graph:

```
Exposure adjustment
    → Temperature & tint
    → Saturation
    → Per-channel tone curves (R, G, B, Alpha — 5-point cubic spline)
    → Split toning (shadow hue + highlight hue)
    → Fade (black lift)
    → Film clamp
    → Vignette
    → CIDissolveTransition (intensity blend with original)
```

Tone curves are encoded as 5 control points (shadows, darks, midtones, lights, highlights), solved as a constrained cubic polynomial, and evaluated on the GPU via `CIColorPolynomial`.

### Grain Shader (Metal)

`GrainKernel.metal` runs as a compute kernel over every output pixel. It mixes:

- **Gaussian noise** — fine-grain base texture
- **Simplex 2D noise** — large-scale tonal variation
- **Worley noise** — crystal clumping effect

Grain operates in the optical density domain (logarithmic), matching the physics of silver halide development. A frame-count–based time coordinate prevents floating-point precision loss on long sessions.

### State Management

- `CameraState` (`@Observable`) — filter selection, grain settings, EV, lens index, capture mode
- `CameraManager` — owns and drives `AVCaptureSession` on a dedicated serial queue
- `CaptureDeviceManager` — enumerates lenses sorted by focal length
- `SubscriptionManager` — StoreKit 2 transaction listener, persists `isPro` to UserDefaults
- Per-filter intensity map persisted in UserDefaults

---

## Requirements

- iOS 17.0+
- Swift 6.0
- Xcode 16+
- Physical device required (camera not available in Simulator)

---

## Building

1. Clone the repo
2. Open `Camera.xcodeproj` in Xcode
3. Select your development team in *Signing & Capabilities*
4. Run on a physical iPhone

No additional setup needed — no SPM packages, no CocoaPods.

---

## Subscription

The app uses a freemium model. Free users have access to 3 presets (`clean`, `mono`, `portra`). A Pro subscription unlocks all 28 presets and removes the watermark overlay on locked filters.

Subscription products are configured in `Products.storekit`. For local testing, use Xcode's StoreKit sandbox.

---

## License

This project is licensed under the **PolyForm Noncommercial License 1.0.0** — see [LICENSE](LICENSE) for full terms.

**In short:** you are free to view, fork, and modify the code for noncommercial purposes. Commercial use is not permitted without explicit written permission from the author.

© 2024 Tronin Denis
