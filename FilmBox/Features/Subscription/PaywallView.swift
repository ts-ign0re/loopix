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

    /// All processed preview images (preloaded)
    @State private var processedImages: [CGImage?] = Array(repeating: nil, count: paywallTestImageNames.count)

    /// Loading state
    @State private var isLoading = true

    /// Purchase in progress
    @State private var isPurchasing = false

    /// Filters loaded flag for scroll
    @State private var filtersReady = false

    /// Show terms sheet
    @State private var showTerms = false

    /// Task for cancelling previous image processing
    @State private var processingTask: Task<Void, Never>?

    // MARK: - Constants

    private let yearlyPrice: Double = 39.99

    /// Shared CIContext to avoid memory leaks
    private static let sharedContext: CIContext = {
        CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false,
            .cacheIntermediates: false
        ])
    }()
    private var monthlyPrice: Double { (yearlyPrice / 12 * 100).rounded() / 100 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Close button
                    closeButton

                    // Image preview (half screen) - using ScrollView for smooth swipe
                    imageCarousel(height: geometry.size.height * 0.45)

                    // Page indicator dots
                    pageIndicator
                        .padding(.top, 12)

                    // Filter strip with gradients
                    filterStripWithGradients
                        .padding(.top, 12)

                    Spacer()

                    // Pricing and purchase button
                    purchaseSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 34)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Track paywall view
            Analytics.shared.trackScreen(.paywall)

            setupFilters()
            await loadSourceImages()
        }
        .onChange(of: selectedFilter) { _, newFilter in
            // Cancel previous processing task
            processingTask?.cancel()
            processingTask = Task {
                await processAllImages()
            }
        }
        .onDisappear {
            // Clean up on dismiss
            processingTask?.cancel()
            processingTask = nil
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

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<paywallTestImageNames.count, id: \.self) { index in
                Circle()
                    .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Image Carousel (smooth scrolling)

    private let carouselSpacing: CGFloat = 16

    private func imageCarousel(height: CGFloat) -> some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - carouselSpacing * 2

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: carouselSpacing) {
                    ForEach(0..<paywallTestImageNames.count, id: \.self) { index in
                        ZStack {
                            if let cgImage = processedImages[index] {
                                Image(decorative: cgImage, scale: 1.0)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: cardWidth, height: height)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: cardWidth, height: height)
                                    .overlay {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white.opacity(0.3))
                                        }
                                    }
                            }
                        }
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, carouselSpacing)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { currentImageIndex },
                set: { if let newValue = $0 { currentImageIndex = newValue } }
            ))
        }
        .frame(height: height)
    }

    // MARK: - Filter Strip with Gradients

    private var filterStripWithGradients: some View {
        ZStack {
            // Filter scroll view
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(shuffledFilters) { filter in
                            filterCell(filter)
                                .id(filter.id)
                        }
                    }
                    .padding(.horizontal, 40) // Extra padding for gradient overlay
                }
                .frame(height: 100)
                .onChange(of: filtersReady) { _, ready in
                    if ready, let id = selectedFilterID {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }

            // Left gradient fade
            HStack {
                LinearGradient(
                    colors: [.black, .black.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 40)
                .allowsHitTesting(false)

                Spacer()

                // Right gradient fade
                LinearGradient(
                    colors: [.black.opacity(0), .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 40)
                .allowsHitTesting(false)
            }
            .frame(height: 100)
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
            Text("paywall.unlock_filters".localized)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            // Monthly price callout
            Text(String(format: "paywall.monthly_price".localized, String(format: "%.2f", monthlyPrice)))
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
                        Text(String(format: "paywall.get_pro".localized, String(format: "%.2f", yearlyPrice)))
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

            // Restore purchases & Terms
            HStack(spacing: 16) {
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Text("paywall.restore".localized)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Text("·")
                    .foregroundStyle(.white.opacity(0.3))

                Button {
                    showTerms = true
                } label: {
                    Text("paywall.terms".localized)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsWebView()
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

        // Mark filters as ready for scroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            filtersReady = true
        }
    }

    private func loadSourceImages() async {
        isLoading = true

        let targetWidth: CGFloat = 800
        var images: [CIImage] = []

        for name in paywallTestImageNames {
            var ciImage: CIImage?

            if let url = Bundle.main.url(forResource: name, withExtension: "jpeg") {
                ciImage = CIImage(contentsOf: url)
            } else if let url = Bundle.main.url(forResource: name, withExtension: "jpg") {
                ciImage = CIImage(contentsOf: url)
            }

            // Pre-scale to target size to reduce memory
            if let image = ciImage {
                let scale = targetWidth / image.extent.width
                let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                images.append(scaled)
            }
        }

        sourceImages = images

        // Process all images for smooth carousel
        await processAllImages()

        isLoading = false
    }

    /// Process all images in parallel for smooth carousel scrolling
    private func processAllImages() async {
        guard !sourceImages.isEmpty, let filter = selectedFilter else { return }

        // Check for cancellation early
        guard !Task.isCancelled else { return }

        let context = Self.sharedContext
        let imagesToProcess = sourceImages

        await withTaskGroup(of: (Int, CGImage?).self) { group in
            for (index, source) in imagesToProcess.enumerated() {
                group.addTask {
                    // Check cancellation
                    guard !Task.isCancelled else { return (index, nil) }

                    // Apply filter (source already pre-scaled)
                    let processed = await FilterEngine.shared.apply(filter, to: source)

                    // Check cancellation before expensive render
                    guard !Task.isCancelled else { return (index, nil) }

                    // Render to CGImage
                    let cgImage = context.createCGImage(processed, from: processed.extent)
                    return (index, cgImage)
                }
            }

            for await (index, cgImage) in group {
                // Check cancellation
                guard !Task.isCancelled else { break }

                await MainActor.run {
                    if index < processedImages.count {
                        processedImages[index] = cgImage
                    }
                }
            }
        }
    }

    // MARK: - Purchase Actions

    private func purchase() async {
        isPurchasing = true

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
struct FilterPreviewThumbnail: View {
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

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        PaywallView()
    }
}
