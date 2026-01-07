//
//  PaywallView.swift
//  FilmBox
//
//  Paywall screen with filter previews and subscription purchase
//

import SwiftUI
import CoreImage

// MARK: - Test Image Names (same as RecipePreviewGrid)

private let paywallTestImageNames = [
    "IMG_1247",
    "IMG_1248",
    "IMG_1249",
    "IMG_1250",
    "IMG_1251",
    "IMG_1252",
    "IMG_1253",
    "IMG_1254",
    "IMG_1263"
]

// MARK: - Paywall View

@available(iOS 17.0, *)
struct PaywallView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// All available filters (FILM + B&W) in random order
    @State private var shuffledFilters: [FilterPreset] = []

    /// Currently selected filter
    @State private var selectedFilter: FilterPreset?

    /// Selected filter index for ScrollViewReader
    @State private var selectedFilterID: UUID?

    /// Source images for preview
    @State private var sourceImages: [CIImage] = []

    /// Current image index in carousel
    @State private var currentImageIndex: Int = 0

    /// Processed preview image
    @State private var processedImage: CGImage?

    /// Loading state
    @State private var isLoading = true

    /// Purchase in progress
    @State private var isPurchasing = false

    // MARK: - Constants

    private let yearlyPrice: Double = 39.99
    private var monthlyPrice: Double { (yearlyPrice / 12).rounded(to: 2) }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Close button
                    closeButton

                    // Image preview (half screen)
                    imagePreview(height: geometry.size.height * 0.45)

                    // Filter strip
                    filterStrip
                        .padding(.top, 16)

                    Spacer()

                    // Pricing and purchase button
                    purchaseSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 34)
                }
            }
        }
        .task {
            // Track paywall view
            Analytics.shared.trackScreen(.paywall)

            setupFilters()
            await loadSourceImages()
        }
        .onChange(of: selectedFilter) { _, newFilter in
            Task {
                await processCurrentImage()
            }
        }
        .onChange(of: currentImageIndex) { _, _ in
            Task {
                await processCurrentImage()
            }
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.trailing, 8)
    }

    // MARK: - Image Preview

    private func imagePreview(height: CGFloat) -> some View {
        TabView(selection: $currentImageIndex) {
            ForEach(0..<paywallTestImageNames.count, id: \.self) { index in
                ZStack {
                    if let cgImage = processedImage, index == currentImageIndex {
                        Image(decorative: cgImage, scale: 1.0)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white.opacity(0.3))
                                }
                            }
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: height)
        .padding(.horizontal, 16)
    }

    // MARK: - Filter Strip

    private var filterStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(shuffledFilters) { filter in
                        filterCell(filter)
                            .id(filter.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 100)
            .onAppear {
                // Scroll to selected filter (center)
                if let id = selectedFilterID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func filterCell(_ filter: FilterPreset) -> some View {
        let isSelected = selectedFilter?.id == filter.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
                selectedFilterID = filter.id
            }
        } label: {
            VStack(spacing: 6) {
                // Filter preview thumbnail
                FilterPreviewThumbnail(filter: filter)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
                    )

                // Filter name
                Text(filter.name)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(isSelected ? .yellow : .white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            // Title
            Text("unlock all filters")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            // Monthly price callout
            Text("only $\(String(format: "%.2f", monthlyPrice)) / month")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            // Purchase button with yearly price
            Button {
                Task {
                    await purchase()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    } else {
                        Text("get pro — $\(String(format: "%.2f", yearlyPrice)) / year")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(Color.yellow)
                )
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing)

            // Restore purchases
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("restore purchases")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Setup

    private func setupFilters() {
        // Get all FILM and B&W filters
        let filmFilters = FilmEmulations.all.filter { $0.category == .film }
        let bwFilters = FilmEmulations.all.filter { $0.category == .bw }

        // Combine and shuffle
        var allFilters = filmFilters + bwFilters
        allFilters.shuffle()
        shuffledFilters = allFilters

        // Select random filter from the middle
        if !allFilters.isEmpty {
            let middleIndex = allFilters.count / 2
            let randomOffset = Int.random(in: -2...2)
            let selectedIndex = max(0, min(allFilters.count - 1, middleIndex + randomOffset))
            selectedFilter = allFilters[selectedIndex]
            selectedFilterID = allFilters[selectedIndex].id
        }
    }

    private func loadSourceImages() async {
        isLoading = true

        var images: [CIImage] = []

        for name in paywallTestImageNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "jpeg"),
               let ciImage = CIImage(contentsOf: url) {
                images.append(ciImage)
            } else if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                      let ciImage = CIImage(contentsOf: url) {
                images.append(ciImage)
            }
        }

        sourceImages = images

        // Process initial image
        await processCurrentImage()

        isLoading = false
    }

    private func processCurrentImage() async {
        guard currentImageIndex < sourceImages.count,
              let filter = selectedFilter else { return }

        let source = sourceImages[currentImageIndex]

        let context = CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false
        ])

        // Scale for performance
        let targetWidth: CGFloat = 800
        let scale = targetWidth / source.extent.width
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Apply filter
        let processed = await FilterEngine.shared.apply(filter, to: scaled)

        // Render to CGImage
        let cgImage = context.createCGImage(processed, from: processed.extent)

        await MainActor.run {
            self.processedImage = cgImage
        }
    }

    // MARK: - Purchase Actions

    private func purchase() async {
        isPurchasing = true

        // TODO: Implement StoreKit 2 purchase
        do {
            try await SubscriptionManager.shared.purchase()
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Purchase failed: \(error)")
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true

        // TODO: Implement restore
        do {
            try await SubscriptionManager.shared.restore()
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Restore failed: \(error)")
        }

        isPurchasing = false
    }
}

// MARK: - Filter Preview Thumbnail

@available(iOS 17.0, *)
private struct FilterPreviewThumbnail: View {
    let filter: FilterPreset

    @StateObject private var previewLoader = FilterPreviewLoader()

    var body: some View {
        ZStack {
            if let cgImage = previewLoader.image {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Gradient placeholder
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    ProgressView()
                        .tint(.white.opacity(0.3))
                        .scaleEffect(0.7)
                }
            }
        }
        .onAppear {
            previewLoader.load(preset: filter)
        }
    }

    private var gradientColors: [Color] {
        switch filter.category {
        case .film:
            return [Color.purple.opacity(0.4), Color.pink.opacity(0.3)]
        case .bw:
            return [Color.gray.opacity(0.6), Color.black.opacity(0.8)]
        default:
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.6)]
        }
    }
}

// MARK: - Double Rounding Helper

private extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        PaywallView()
    }
}
