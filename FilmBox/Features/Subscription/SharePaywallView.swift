//
//  SharePaywallView.swift
//  FilmBox
//
//  Paywall shown when user tries to share a recipe (QR code export)
//  Different motivation: community sharing, helping others
//

import SwiftUI

@available(iOS 17.0, *)
struct SharePaywallView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var isPurchasing = false
    @State private var showTerms = false
    @State private var sortedFilters: [FilterPreset] = []
    @State private var centerFilterID: UUID?
    @State private var filtersReady = false

    // MARK: - Constants

    private let yearlyPrice: Double = 39.99
    private var monthlyPrice: Double { (yearlyPrice / 12 * 100).rounded() / 100 }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                closeButton

                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Image(systemName: "qrcode")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(.yellow)
                    }

                    // Title & subtitle
                    VStack(spacing: 12) {
                        Text("paywall.share.title".localized)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("paywall.share.subtitle".localized)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "arrow.up.circle.fill", text: "paywall.share.feature.export".localized)
                        featureRow(icon: "person.2.fill", text: "paywall.share.feature.share".localized)
                        featureRow(icon: "arrow.down.circle.fill", text: "paywall.share.feature.import".localized)
                        featureRow(icon: "sparkles", text: "paywall.share.feature.filters".localized)
                    }
                    .padding(.horizontal, 24)

                    // Filter strip
                    filterStripWithGradients
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Purchase section
                purchaseSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            Analytics.shared.trackScreen("paywall_share")
            setupFilters()
        }
    }

    // MARK: - Setup

    private func setupFilters() {
        // Get all FILM and B&W filters
        let filmFilters = FilmEmulations.all.filter { $0.category == .film }
        let bwFilters = FilmEmulations.all.filter { $0.category == .bw }
        let allFilters = filmFilters + bwFilters

        // Group by brand
        let fujiFilters = allFilters.filter { $0.name.lowercased().contains("fuji") }.sorted { $0.name < $1.name }
        let kodakFilters = allFilters.filter { $0.name.lowercased().contains("kodak") }.sorted { $0.name < $1.name }
        let cinestillFilters = allFilters.filter { $0.name.lowercased().contains("cinestill") }.sorted { $0.name < $1.name }

        let otherFilters = allFilters.filter { filter in
            let name = filter.name.lowercased()
            return !name.contains("fuji") && !name.contains("kodak") && !name.contains("cinestill")
        }.sorted { $0.name < $1.name }

        // Arrange: Fuji (left) → Kodak (center) → CineStill → Others
        sortedFilters = fujiFilters + kodakFilters + cinestillFilters + otherFilters

        // Set center filter to first Kodak filter
        if let firstKodak = kodakFilters.first {
            centerFilterID = firstKodak.id
        }

        // Mark filters as ready for scroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            filtersReady = true
        }
    }

    // MARK: - Filter Strip with Gradients

    private var filterStripWithGradients: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(sortedFilters) { filter in
                            filterCell(filter)
                                .id(filter.id)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(height: 100)
                .onChange(of: filtersReady) { _, ready in
                    if ready, let id = centerFilterID {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }

            // Gradient overlays
            HStack {
                LinearGradient(
                    colors: [.black, .black.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 40)
                .allowsHitTesting(false)

                Spacer()

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
        VStack(spacing: 6) {
            FilterPreviewThumbnail(filter: filter)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(filter.name)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .frame(width: 70)
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

    // MARK: - Feature Row

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.yellow)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            // Monthly price callout
            Text(String(format: "paywall.monthly_price".localized, String(format: "%.2f", monthlyPrice)))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            // Purchase button
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
                        Text(String(format: "paywall.share.button".localized, String(format: "%.2f", yearlyPrice)))
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
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showTerms) {
            TermsWebView()
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

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        SharePaywallView()
    }
}
