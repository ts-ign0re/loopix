import SwiftUI
import Charts

// MARK: - Histogram View

/// Displays a histogram for the current image
struct HistogramView: View {

    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    @State private var histogramData: HistogramData?
    @State private var selectedChannel: HistogramChannel = .luminance

    // MARK: - Histogram Channel

    enum HistogramChannel: String, CaseIterable {
        case luminance = "Luminance"
        case red = "Red"
        case green = "Green"
        case blue = "Blue"
        case rgb = "RGB"

        var color: Color {
            switch self {
            case .luminance: return .white
            case .red: return .red
            case .green: return .green
            case .blue: return .blue
            case .rgb: return .white
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Histogram chart
            histogramChart
                .frame(maxWidth: .infinity)

            // Channel selector
            channelPicker
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .task(id: viewModel.currentImage) {
            await loadHistogram()
        }
    }

    // MARK: - Histogram Chart

    @ViewBuilder
    private var histogramChart: some View {
        if let data = histogramData {
            Chart {
                switch selectedChannel {
                case .luminance:
                    ForEach(Array(data.luminance.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.white.opacity(0.8))
                    }

                case .red:
                    ForEach(Array(data.red.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.red.opacity(0.8))
                    }

                case .green:
                    ForEach(Array(data.green.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.green.opacity(0.8))
                    }

                case .blue:
                    ForEach(Array(data.blue.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.blue.opacity(0.8))
                    }

                case .rgb:
                    ForEach(Array(data.red.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.red.opacity(0.6))
                    }

                    ForEach(Array(data.green.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.green.opacity(0.6))
                    }

                    ForEach(Array(data.blue.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Bin", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.black.opacity(0.3))
            }
        } else {
            // Loading placeholder
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .overlay {
                    ProgressView()
                        .tint(.white)
                }
        }
    }

    // MARK: - Channel Picker

    private var channelPicker: some View {
        Menu {
            ForEach(HistogramChannel.allCases, id: \.self) { channel in
                Button {
                    selectedChannel = channel
                } label: {
                    HStack {
                        Text(channel.rawValue)
                        if selectedChannel == channel {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "chart.bar.xaxis")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Helper Methods

    private func loadHistogram() async {
        histogramData = await viewModel.calculateHistogram()
    }
}

// MARK: - Preview

#Preview("Histogram View") {
    @Previewable @State var viewModel = EditorViewModel(
        uiImage: UIImage(systemName: "photo.fill")!
    )

    HistogramView(viewModel: viewModel)
        .frame(height: 80)
        .padding()
        .background(Color.black)
}
