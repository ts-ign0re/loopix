import SwiftUI

struct EVWheelView: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onChange: (Float) -> Void

    // Track the value at drag start so we accumulate from a known point
    @State private var valueAtDragStart: Float = 0
    @State private var isDragging = false
    private let tickSpacing: CGFloat = 12
    private let tickCount = 61 // -3.0 to +3.0 in 0.1 steps
    // Points of drag per 1.0 EV — higher = less sensitive
    private let pointsPerEV: CGFloat = 200

    var body: some View {
        VStack(spacing: 4) {
            // EV value display
            Text(String(format: "%+.1f EV", value))
                .font(CameraTheme.monoFont)
                .foregroundColor(value == 0 ? CameraTheme.textSecondary : CameraTheme.controlActive)

            // Wheel
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2

                ZStack {
                    // Center marker (same height as center tick, bottom-aligned)
                    Rectangle()
                        .fill(CameraTheme.controlActive)
                        .frame(width: 2, height: 16)
                        .position(x: centerX, y: 12)

                    // Ticks
                    Canvas { context, size in
                        let totalWidth = CGFloat(tickCount - 1) * tickSpacing
                        let normalizedValue = CGFloat(
                            (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                        )
                        let offset = centerX - normalizedValue * totalWidth

                        for tickIndex in 0..<tickCount {
                            let tickX = CGFloat(tickIndex) * tickSpacing + offset
                            guard tickX > -tickSpacing && tickX < size.width + tickSpacing else { continue }

                            let isMajor = tickIndex % 10 == 0
                            let isCenter = tickIndex == tickCount / 2
                            let height: CGFloat = isCenter ? 16 : (isMajor ? 12 : 6)
                            let opacity: Double = isCenter ? 1.0 : (isMajor ? 0.6 : 0.3)

                            var path = Path()
                            path.move(to: CGPoint(x: tickX, y: 20 - height))
                            path.addLine(to: CGPoint(x: tickX, y: 20))
                            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: isMajor ? 1.5 : 1)
                        }
                    }
                    .frame(height: 20)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { drag in
                            if !isDragging {
                                isDragging = true
                                valueAtDragStart = value
                            }
                            let evDelta = Float(-drag.translation.width / pointsPerEV)
                            let newValue = valueAtDragStart + evDelta
                            let clamped = max(range.lowerBound, min(range.upperBound, newValue))
                            let snapped = (clamped * 10).rounded() / 10
                            if snapped != value {
                                value = snapped
                                onChange(value)
                            }
                        }
                        .onEnded { _ in
                            valueAtDragStart = value
                            isDragging = false
                        }
                )
                .onTapGesture(count: 2) {
                    // Double-tap to reset to 0
                    value = 0
                    valueAtDragStart = 0
                    onChange(0)
                }
            }
            .frame(height: 20)
        }
        .padding(.horizontal, CameraTheme.paddingXL)
        .frame(height: 40)
        .onAppear {
            valueAtDragStart = value
        }
        .onChange(of: value) { _, newValue in
            // Sync only when value changes externally (not during our drag)
            if !isDragging {
                valueAtDragStart = newValue
            }
        }
    }
}
