//
//  RecipePreviewGrid.swift
//  FilmBox
//
//  Real-time carousel preview for filter editing
//

import SwiftUI
import CoreImage

// MARK: - Test Image Names

private let testImageNames = [
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

// MARK: - Recipe Preview Grid

@available(iOS 17.0, *)
struct RecipePreviewGrid: View {

    // MARK: - Input

    /// Current filter parameters to preview
    let parameters: FilterParameters

    // MARK: - State

    @State private var sourceImages: [CIImage] = []
    @State private var processedImages: [CGImage?] = Array(repeating: nil, count: 9)
    @State private var isLoading = true
    @State private var currentIndex: Int = 0

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Carousel
                TabView(selection: $currentIndex) {
                    ForEach(0..<9, id: \.self) { index in
                        CarouselCell(
                            image: processedImages[safe: index] ?? nil,
                            isLoading: isLoading && processedImages[safe: index] == nil
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: geometry.size.height - 24)

                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<9, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.yellow : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 24)
            }
        }
        .background(Color.black)
        .task {
            await loadSourceImages()
        }
        .onChange(of: parameters) { _, newParams in
            Task {
                await processAllImages(with: newParams)
            }
        }
    }

    // MARK: - Image Loading

    private func loadSourceImages() async {
        isLoading = true

        var images: [CIImage] = []

        for name in testImageNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "jpeg"),
               let ciImage = CIImage(contentsOf: url) {
                images.append(ciImage)
            } else if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                      let ciImage = CIImage(contentsOf: url) {
                images.append(ciImage)
            }
        }

        sourceImages = images

        // Process with current parameters
        await processAllImages(with: parameters)

        isLoading = false
    }

    // MARK: - Image Processing

    private func processAllImages(with params: FilterParameters) async {
        guard !sourceImages.isEmpty else { return }

        let context = CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false
        ])

        // Process all images concurrently for better performance
        // Use higher resolution for carousel (600px instead of 300px)
        await withTaskGroup(of: (Int, CGImage?).self) { group in
            for (index, source) in sourceImages.enumerated() {
                group.addTask {
                    // Scale down for performance (larger for carousel)
                    let targetWidth: CGFloat = 600
                    let scale = targetWidth / source.extent.width
                    let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

                    // Apply filter (FilterEngine is an actor, so this is thread-safe)
                    let processed = await FilterEngine.shared.apply(params, to: scaled)

                    // Render to CGImage
                    let cgImage = context.createCGImage(processed, from: processed.extent)
                    return (index, cgImage)
                }
            }

            // Collect results and update UI progressively
            for await (index, cgImage) in group {
                await MainActor.run {
                    if index < processedImages.count {
                        processedImages[index] = cgImage
                    }
                }
            }
        }
    }
}

// MARK: - Carousel Cell

private struct CarouselCell: View {
    let image: CGImage?
    let isLoading: Bool

    var body: some View {
        GeometryReader { geometry in
            if let cgImage = image {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        ProgressView()
                            .tint(.white.opacity(0.3))
                    }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        RecipePreviewGrid(parameters: FilterParameters())
            .frame(height: 400)
            .background(Color.black)
    }
}
