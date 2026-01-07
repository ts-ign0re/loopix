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
                        Text("share your recipes")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("help others discover amazing looks.\nshare your custom recipes via QR code.")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "arrow.up.circle.fill", text: "export recipes as QR codes")
                        featureRow(icon: "person.2.fill", text: "share with friends & community")
                        featureRow(icon: "arrow.down.circle.fill", text: "import recipes from others")
                        featureRow(icon: "sparkles", text: "unlock all 30+ film filters")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Purchase section
                purchaseSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .task {
            Analytics.shared.trackScreen("paywall_share")
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
            Text("only $\(String(format: "%.2f", monthlyPrice)) / month")
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
                        Text("unlock sharing — $\(String(format: "%.2f", yearlyPrice)) / year")
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
