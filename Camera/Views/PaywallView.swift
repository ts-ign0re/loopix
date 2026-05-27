import SwiftUI
import StoreKit
import CoreImage

private let paywallImageNames = [
    "IMG_1247", "IMG_1248", "IMG_1249", "IMG_1250",
    "IMG_1251", "IMG_1252", "IMG_1253", "IMG_1254", "IMG_1263"
]

/// Filter indices into BuiltInFilters.all — one per carousel image
private let paywallFilterIndices = [1, 2, 6, 14, 18, 17, 20, 16, 23]
// Tri-X, BwXX, HP5, Copper, Velvia, Frost, Chrome, Flare, Ultra

// swiftlint:disable type_body_length file_length function_body_length
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentImageIndex: Int = 0
    @State private var selectedPlan: SubscriptionProduct = .yearlyPro
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var filteredImages: [Int: UIImage] = [:]

    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    private var yearlyProduct: Product? {
        subscription.products.first { $0.id == SubscriptionProduct.yearlyPro.rawValue }
    }

    private var monthlyProduct: Product? {
        subscription.products.first { $0.id == SubscriptionProduct.monthlyPro.rawValue }
    }

    private var yearlyMonthlyPriceString: String {
        if let product = yearlyProduct {
            let monthly = product.price / 12
            return product.priceFormatStyle.format(monthly)
        }
        return ""
    }

    /// Savings % of yearly vs monthly
    private var savingsPercent: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let yearlyEquiv = monthly.price * 12
        let savings = (yearlyEquiv - yearly.price) / yearlyEquiv * 100
        return NSDecimalNumber(decimal: savings).intValue
    }

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
                        Text("unlock all film\npresets")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        // Subtitle
                        Text("28 film presets, no watermark, full resolution export")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
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

                // (close button is inside carousel)
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
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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
        .task { await renderFilteredImages() }
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

    private func renderFilteredImages() async {
        let screenWidth = UIScreen.main.bounds.width
        let scale = UIScreen.main.scale
        let targetWidth = screenWidth * scale
        let filters = BuiltInFilters.all

        let results: [Int: UIImage] = await Task.detached(priority: .userInitiated) {
            let context = CIContext()
            var images: [Int: UIImage] = [:]

            for index in paywallImageNames.indices {
                let filter = filters[paywallFilterIndices[index]]
                guard let uiImage = UIImage(named: paywallImageNames[index]),
                      let ciInput = CIImage(image: uiImage) else { continue }

                let ratio = min(targetWidth / ciInput.extent.width, 1.0)
                let scaled = ratio < 1.0
                    ? ciInput.transformed(by: .init(scaleX: ratio, y: ratio))
                    : ciInput

                let filtered = LiveFilterPipeline.apply(filter, to: scaled)
                guard let cgImage = context.createCGImage(filtered, from: filtered.extent) else { continue }
                images[index] = UIImage(cgImage: cgImage)
            }

            return images
        }.value

        filteredImages = results
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            if monthlyProduct != nil || yearlyProduct != nil || !subscription.isLoading {
                // Plan cards
                HStack(spacing: 10) {
                    planCard(
                        plan: .monthlyPro,
                        title: "Monthly",
                        price: monthlyProduct?.displayPrice ?? "$3.99",
                        detail: "28 + all future presets",
                        badge: nil
                    )
                    planCard(
                        plan: .yearlyPro,
                        title: "Yearly",
                        price: yearlyProduct?.displayPrice ?? "$29.99",
                        detail: yearlyMonthlyPriceString.isEmpty ? "$2.49 / mo" : yearlyMonthlyPriceString + " / mo",
                        badge: savingsPercent > 0 ? "-\(savingsPercent)%" : "-38%"
                    )
                }

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
                            Text(ctaText)
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

    private var ctaText: String {
        if selectedPlan == .yearlyPro {
            let price = yearlyProduct?.displayPrice ?? "$29.99"
            return "Get Pro — \(price) / year"
        } else {
            let price = monthlyProduct?.displayPrice ?? "$3.99"
            return "Get Pro — \(price) / month"
        }
    }

    private func planCard(
        plan: SubscriptionProduct,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Badge
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color("BrandYellow"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.bottom, 8)
                } else {
                    Spacer().frame(height: 24)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(plan == .yearlyPro ? Color("BrandYellow") : Color(white: 0.5))
                    .padding(.top, 2)

                Spacer()

                Text(price)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color("BrandYellow").opacity(0.7) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
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
            if subscription.products.isEmpty {
                await subscription.loadProducts()
            }
            try await subscription.purchase(selectedPlan.rawValue)
            dismiss()
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
            errorMessage = "No active subscription found."
        }

        isPurchasing = false
    }
}
// swiftlint:enable type_body_length file_length function_body_length
