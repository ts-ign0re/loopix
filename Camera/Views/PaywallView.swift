import SwiftUI
import StoreKit
import CoreImage
import Combine

private let paywallImageNames = [
    "IMG_1251", "IMG_1253", "IMG_1250", "IMG_1254", "IMG_1263", "IMG_1252"
]

/// Filter indices into BuiltInFilters.all — one per carousel image.
/// Colour presets only; B&W samples need their own dedicated photos.
private let paywallFilterIndices = [18, 20, 14, 16, 23, 17]
// Velvia, Chrome, Copper, Flare, Ultra, Frost

// swiftlint:disable type_body_length function_body_length file_length
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentImageIndex: Int = 0
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var filteredImages: [Int: UIImage] = [:]

    private let autoAdvance = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    private var lifetimeProduct: Product? { subscription.lifetimeProduct }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Hero image carousel
                    imageCarousel(height: geometry.size.height * 0.45)

                    // Content
                    VStack(spacing: 0) {
                        // Title
                        Text("shoot.\nthat's the edit.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        // Subtitle
                        Text("Film never gave you a second take. You pressed the shutter and "
                             + "that was the photo. Loopix is the same: pick a look, press the "
                             + "button, the picture is done.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .padding(.horizontal, 24)

                        // Feature list
                        featureList
                            .padding(.top, 18)
                            .padding(.horizontal, 24)

                        Spacer()

                        // Price card + CTA
                        purchaseSection
                            .padding(.horizontal, 24)

                        // Footer
                        footer
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Image Carousel

    private func imageCarousel(height: CGFloat) -> some View {
        ZStack {
            // Paging carousel
            TabView(selection: $currentImageIndex) {
                ForEach(0..<paywallImageNames.count, id: \.self) { index in
                    ZStack {
                        if let img = filteredImages[index] {
                            // Already rendered at the exact frame size — no per-frame
                            // resampling, so paging stays smooth.
                            Image(uiImage: img)
                                .resizable()
                                .frame(width: UIScreen.main.bounds.width, height: height)
                                .clipped()
                        } else {
                            Image(paywallImageNames[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width, height: height)
                                .clipped()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Overlays
            VStack {
                // Close button (top-right, inside rounded area)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 24)

                Spacer()

                // Bottom: gradient + filter badge + dots
                ZStack(alignment: .bottom) {
                    // Gradient fade
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 140)

                    VStack(alignment: .leading, spacing: 12) {
                        // Filter card badge (bottom-left)
                        filterBadge(for: currentImageIndex)

                        // Page dots (centered)
                        HStack(spacing: 6) {
                            ForEach(0..<paywallImageNames.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.35))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                }
            }
            .allowsHitTesting(true)
        }
        .frame(height: height)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .task { await renderFilteredImages(height: height) }
        .onReceive(autoAdvance) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentImageIndex = (currentImageIndex + 1) % paywallImageNames.count
            }
        }
    }

    // MARK: - Filter Badge (matches FilterCardView style)

    private func filterBadge(for index: Int) -> some View {
        let filter = BuiltInFilters.all[paywallFilterIndices[index]]

        return VStack(alignment: .leading, spacing: 4) {
            Text(filter.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            LinearGradient(
                colors: paletteColors(for: filter),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 60, height: 3)
            .clipShape(Capsule())

            Text(filter.tagline)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.2), lineWidth: 0.5)
        )
    }

    private func paletteColors(for filter: CameraFilter) -> [Color] {
        if filter.id == "clean" {
            return [Color(white: 0.4), Color(white: 0.55)]
        }
        if filter.isMonochrome && filter.contrast > 20 {
            return [Color(white: 0.15), Color(white: 0.85)]
        }
        if filter.isMonochrome {
            let hue = filter.shadowTintStrength > 0
                ? Double(filter.shadowHue) / 360
                : 0.08
            return [
                Color(hue: hue, saturation: 0.3, brightness: 0.3),
                Color(hue: hue, saturation: 0.15, brightness: 0.6)
            ]
        }
        let sSat = min(Double(filter.shadowTintStrength) * 14 + 0.25, 0.85)
        let hSat = min(Double(filter.highlightTintStrength) * 14 + 0.25, 0.85)
        return [
            Color(hue: Double(filter.shadowHue) / 360, saturation: sSat, brightness: 0.5),
            Color(hue: Double(filter.highlightHue) / 360, saturation: hSat, brightness: 0.65)
        ]
    }

    // MARK: - Filter Rendering

    private func renderFilteredImages(height: CGFloat) async {
        let scale = UIScreen.main.scale
        let targetWidth = UIScreen.main.bounds.width * scale
        let targetHeight = height * scale
        let filters = BuiltInFilters.all

        let results: [Int: UIImage] = await Task.detached(priority: .userInitiated) {
            let context = CIContext()
            var images: [Int: UIImage] = [:]

            for index in paywallImageNames.indices {
                let filter = filters[paywallFilterIndices[index]]
                guard let uiImage = UIImage(named: paywallImageNames[index]),
                      let ciInput = CIImage(image: uiImage) else { continue }

                // Aspect-fill the carousel frame, then centre-crop, so the stored
                // image matches the on-screen size 1:1 and paging doesn't resample.
                let fillScale = max(targetWidth / ciInput.extent.width,
                                    targetHeight / ciInput.extent.height)
                let scaled = ciInput.transformed(by: .init(scaleX: fillScale, y: fillScale))
                let filtered = LiveFilterPipeline.apply(filter, to: scaled)

                let cropRect = CGRect(
                    x: filtered.extent.midX - targetWidth / 2,
                    y: filtered.extent.midY - targetHeight / 2,
                    width: targetWidth, height: targetHeight
                )
                guard let cgImage = context.createCGImage(filtered, from: cropRect) else { continue }
                images[index] = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            }

            return images
        }.value

        filteredImages = results
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: Image(systemName: "film.stack").foregroundStyle(Color("BrandYellow")),
                       "30 film looks: Kodak, Fuji, old cinema stocks")
            featureRow(icon: Image(systemName: "infinity").foregroundStyle(Color("BrandYellow")),
                       "Pay once for all future updates and add-ons")
            featureRow(icon: Text("❤️"),
                       "Your memories, kept in the colors you love")
        }
    }

    private func featureRow(icon: some View, _ text: String) -> some View {
        HStack(spacing: 12) {
            icon
                .font(.system(size: 16, weight: .bold))
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
        }
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            if let product = lifetimeProduct {
                lifetimeCard(product: product)

                // CTA
                Button {
                    Task { await handlePurchase() }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(0.8)
                        } else {
                            Text("Unlock Lifetime — \(product.displayPrice)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("BrandYellow"))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
            } else {
                ProgressView()
                    .tint(.white.opacity(0.5))
                    .frame(height: 100)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
    }

    private func lifetimeCard(product: Product) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lifetime")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("One payment. Yours for life.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color("BrandYellow"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(product.displayPrice)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("one-time")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(white: 0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("BrandYellow").opacity(0.7), lineWidth: 1.5)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 20) {
            Link("Terms of use",
                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Button("Restore") {
                Task { await handleRestore() }
            }
        }
        .font(.system(size: 13, weight: .regular, design: .rounded))
        .foregroundStyle(.white.opacity(0.4))
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await subscription.purchase()
            if subscription.isPro { dismiss() }
        } catch SubscriptionError.userCancelled {
            // ignore
        } catch {
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }

    private func handleRestore() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await subscription.restore()
            dismiss()
        } catch {
            errorMessage = "No previous purchase found."
        }

        isPurchasing = false
    }
}
// swiftlint:enable type_body_length function_body_length file_length
