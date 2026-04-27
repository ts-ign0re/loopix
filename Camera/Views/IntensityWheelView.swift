import SwiftUI

struct IntensityWheelView: View {
    @Binding var value: Float
    let range: ClosedRange<Float> = 0...1

    @State private var valueAtDragStart: Float = 1.0
    @State private var isDragging = false
    private let tickSpacing: CGFloat = 12
    private let tickCount = 21 // 0% to 100% in 5% steps
    private let pointsPerUnit: CGFloat = 250

    var body: some View {
        HStack(spacing: 0) {
            // Wheel
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2

                ZStack {
                    // Center marker
                    Rectangle()
                        .fill(CameraTheme.controlActive)
                        .frame(width: 2, height: 16)
                        .position(x: centerX, y: 10)

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

                            let isMajor = tickIndex % 5 == 0
                            let isEnd = tickIndex == tickCount - 1
                            let height: CGFloat = isEnd ? 16 : (isMajor ? 12 : 6)
                            let opacity: Double = isEnd ? 1.0 : (isMajor ? 0.6 : 0.3)

                            var path = Path()
                            path.move(to: CGPoint(x: tickX, y: 18 - height))
                            path.addLine(to: CGPoint(x: tickX, y: 18))
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
                            let delta = Float(-drag.translation.width / pointsPerUnit)
                            let newValue = valueAtDragStart + delta
                            let clamped = max(range.lowerBound, min(range.upperBound, newValue))
                            let snapped = (clamped * 100).rounded() / 100
                            if snapped != value {
                                value = snapped
                            }
                        }
                        .onEnded { _ in
                            valueAtDragStart = value
                            isDragging = false
                        }
                )
                .onTapGesture(count: 2) {
                    value = 1.0
                    valueAtDragStart = 1.0
                }
            }
            .frame(height: 20)

            // Percentage label — right side
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(value >= 1.0 ? CameraTheme.textSecondary : CameraTheme.controlActive)
                .frame(width: 48, alignment: .trailing)
                .padding(.leading, 8)
        }
        .padding(.leading, CameraTheme.paddingXL)
        .padding(.trailing, CameraTheme.paddingLarge)
        .frame(height: 20)
        .onAppear {
            valueAtDragStart = value
        }
        .onChange(of: value) { _, newValue in
            if !isDragging {
                valueAtDragStart = newValue
            }
        }
    }
}
