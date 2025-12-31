import SwiftUI

// MARK: - Aspect Ratio

/// Predefined aspect ratios for cropping
enum AspectRatio: String, CaseIterable, Identifiable {
    case free = "Free"
    case square = "1:1"
    case fourThree = "4:3"
    case threeTwo = "3:2"
    case sixteenNine = "16:9"
    case nineSixteen = "9:16"
    case twoThree = "2:3"
    case threeFour = "3:4"

    var id: String { rawValue }

    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .threeTwo: return 3.0 / 2.0
        case .sixteenNine: return 16.0 / 9.0
        case .nineSixteen: return 9.0 / 16.0
        case .twoThree: return 2.0 / 3.0
        case .threeFour: return 3.0 / 4.0
        }
    }

    var iconName: String {
        switch self {
        case .free: return "crop"
        case .square: return "square"
        case .fourThree, .threeTwo, .sixteenNine: return "rectangle"
        case .nineSixteen, .twoThree, .threeFour: return "rectangle.portrait"
        }
    }
}

// MARK: - Crop Tab View

/// Crop and transform tab for the editor
struct CropTabView: View {

    // MARK: - Properties

    @Binding var parameters: FilterParameters
    @Binding var cropRect: CGRect?

    /// Image size for crop calculations
    let imageSize: CGSize

    /// Selected aspect ratio
    @State private var selectedAspectRatio: AspectRatio = .free

    /// Current rotation angle in degrees
    @State private var rotationAngle: Double = 0

    /// Whether the image is flipped horizontally
    @State private var isFlippedHorizontally: Bool = false

    /// Whether the image is flipped vertically
    @State private var isFlippedVertically: Bool = false

    /// Whether perspective correction mode is active
    @State private var showingPerspectiveCorrection: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Aspect ratio selector
            aspectRatioSection

            Divider()
                .padding(.vertical, 12)

            // Rotation controls
            rotationSection

            Divider()
                .padding(.vertical, 12)

            // Transform controls
            transformSection

            Spacer()

            // Reset button
            resetSection
        }
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
        .onChange(of: rotationAngle) { _, newValue in
            parameters.rotation = Float(newValue)
        }
    }

    // MARK: - Aspect Ratio Section

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ASPECT RATIO")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AspectRatio.allCases) { ratio in
                        AspectRatioButton(
                            ratio: ratio,
                            isSelected: selectedAspectRatio == ratio
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedAspectRatio = ratio
                                applyCropAspectRatio(ratio)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Rotation Section

    private var rotationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ROTATION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(String(format: "%.1f°", rotationAngle))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            // Rotation wheel/slider
            HStack(spacing: 16) {
                // Quick rotation buttons
                Button {
                    withAnimation {
                        rotationAngle = (rotationAngle - 90).truncatingRemainder(dividingBy: 360)
                    }
                } label: {
                    Image(systemName: "rotate.left")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Fine rotation slider
                Slider(value: $rotationAngle, in: -180...180, step: 0.1)
                    .tint(.accentColor)

                Button {
                    withAnimation {
                        rotationAngle = (rotationAngle + 90).truncatingRemainder(dividingBy: 360)
                    }
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Straighten slider for fine adjustment
            HStack(spacing: 8) {
                Text("-45°")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                GeometryReader { geo in
                    StraightenRuler(value: $rotationAngle, range: -45...45)
                }
                .frame(height: 30)

                Text("+45°")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Transform Section

    private var transformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRANSFORM")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            HStack(spacing: 16) {
                // Flip Horizontal
                TransformButton(
                    icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    title: "Flip H",
                    isActive: isFlippedHorizontally
                ) {
                    withAnimation {
                        isFlippedHorizontally.toggle()
                    }
                }

                // Flip Vertical
                TransformButton(
                    icon: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                    title: "Flip V",
                    isActive: isFlippedVertically
                ) {
                    withAnimation {
                        isFlippedVertically.toggle()
                    }
                }

                // Perspective (Advanced)
                TransformButton(
                    icon: "perspective",
                    title: "Perspective",
                    isActive: showingPerspectiveCorrection
                ) {
                    showingPerspectiveCorrection.toggle()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Button {
            withAnimation {
                resetAll()
            }
        } label: {
            Text("Reset")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .disabled(!hasChanges)
        .opacity(hasChanges ? 1 : 0.5)
    }

    // MARK: - Helpers

    private var hasChanges: Bool {
        rotationAngle != 0 ||
        isFlippedHorizontally ||
        isFlippedVertically ||
        selectedAspectRatio != .free ||
        cropRect != nil
    }

    private func applyCropAspectRatio(_ ratio: AspectRatio) {
        guard let aspectRatio = ratio.ratio else {
            // Free crop - remove constraint
            cropRect = nil
            return
        }

        // Calculate crop rect based on aspect ratio
        let imageAspect = imageSize.width / imageSize.height
        var newRect: CGRect

        if aspectRatio > imageAspect {
            // Crop height
            let newHeight = imageSize.width / aspectRatio
            let yOffset = (imageSize.height - newHeight) / 2
            newRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        } else {
            // Crop width
            let newWidth = imageSize.height * aspectRatio
            let xOffset = (imageSize.width - newWidth) / 2
            newRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        }

        cropRect = newRect
    }

    private func resetAll() {
        selectedAspectRatio = .free
        rotationAngle = 0
        isFlippedHorizontally = false
        isFlippedVertically = false
        cropRect = nil
        parameters.rotation = 0
        parameters.cropRect = nil
    }
}

// MARK: - Aspect Ratio Button

private struct AspectRatioButton: View {
    let ratio: AspectRatio
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: ratio.iconName)
                    .font(.title3)
                    .frame(width: 32, height: 32)

                Text(ratio.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(width: 56, height: 56)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transform Button

private struct TransformButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(isActive ? Color.accentColor : Color(.systemBackground))
                    .foregroundStyle(isActive ? .white : .primary)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Straighten Ruler

private struct StraightenRuler: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let tickCount = 19 // -45 to +45 in 5-degree increments
            let tickSpacing = width / CGFloat(tickCount - 1)

            ZStack {
                // Background
                Rectangle()
                    .fill(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Tick marks
                HStack(spacing: 0) {
                    ForEach(0..<tickCount, id: \.self) { index in
                        let tickValue = -45 + index * 5
                        let isMajor = tickValue % 15 == 0

                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1, height: isMajor ? 16 : 8)

                        if index < tickCount - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 8)

                // Center indicator
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 20)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let percent = gesture.location.x / width
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percent)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var parameters = FilterParameters()
        @State private var cropRect: CGRect?

        var body: some View {
            CropTabView(
                parameters: $parameters,
                cropRect: $cropRect,
                imageSize: CGSize(width: 4000, height: 3000)
            )
        }
    }

    return PreviewWrapper()
}
