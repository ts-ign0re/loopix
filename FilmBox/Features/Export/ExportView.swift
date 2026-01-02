import SwiftUI
import Photos

// MARK: - Export View

/// Main export configuration screen
struct ExportView: View {
    @Bindable var viewModel: ExportViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingShareSheet = false

    /// Convenience initializer with assets
    init(assets: [PHAsset]) {
        self._viewModel = Bindable(wrappedValue: ExportViewModel(assets: assets))
    }

    /// Initializer with assets and per-asset parameters (for edited photos)
    init(assetsWithParameters: [(asset: PHAsset, parameters: FilterParameters?)]) {
        self._viewModel = Bindable(wrappedValue: ExportViewModel(assetsWithParameters: assetsWithParameters))
    }

    /// Initializer with local photos for export from local storage
    init(localPhotos: [(photo: ImportedPhoto, parameters: FilterParameters?)]) {
        self._viewModel = Bindable(wrappedValue: ExportViewModel(localPhotos: localPhotos))
    }

    /// Initializer with existing view model
    init(viewModel: ExportViewModel) {
        self._viewModel = Bindable(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo count section
                photoCountSection

                // Format section
                formatSection

                // Quality section (only for JPEG/WebP)
                if viewModel.settings.format.supportsQuality {
                    qualitySection
                }

                // Size section
                sizeSection

                // Metadata section
                metadataSection

                // Destination section
                destinationSection

                // Export button section
                exportButtonSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ export")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if viewModel.isExporting {
                            viewModel.cancelExport()
                        }
                        dismiss()
                    } label: {
                        Text("cancel")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if !viewModel.exportedURLs.isEmpty {
                    ShareSheet(items: viewModel.exportedURLs)
                }
            }
            .onChange(of: viewModel.exportState) { _, newState in
                handleStateChange(newState)
            }
        }
    }

    // MARK: - Sections

    private var photoCountSection: some View {
        Section {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.secondary)
                Text("\(viewModel.itemCount) photo\(viewModel.itemCount == 1 ? "" : "s") selected")
            }
        }
    }

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $viewModel.settings.format) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.displayName)
                        .tag(format)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Format")
        } footer: {
            Text(formatFooterText)
        }
    }

    private var formatFooterText: String {
        switch viewModel.settings.format {
        case .jpeg:
            return "JPEG offers excellent compatibility with all devices and platforms. Recommended."
        case .png:
            return "PNG provides lossless compression. Best for graphics with transparency."
        case .webp:
            return "WebP offers excellent compression with good quality. Widely supported on web."
        }
    }

    private var qualitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Quality")
                    Spacer()
                    Text("\(viewModel.settings.qualityPercentage)%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { viewModel.settings.quality },
                        set: { viewModel.settings.quality = $0 }
                    ),
                    in: 0.1...1.0,
                    step: 0.05
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("Quality")
        } footer: {
            Text("Higher quality results in larger file sizes.")
        }
    }

    private var sizeSection: some View {
        Section {
            Picker("Size", selection: $viewModel.settings.size) {
                ForEach(ExportSize.allCases, id: \.self) { size in
                    Text(size.displayName)
                        .tag(size)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Size")
        } footer: {
            if let maxDimension = viewModel.settings.maxDimension {
                Text("Images will be resized to fit within \(maxDimension) pixels on the longest edge.")
            } else {
                Text("Images will be exported at their original resolution.")
            }
        }
    }

    private var metadataSection: some View {
        Section {
            Toggle("Preserve EXIF Data", isOn: $viewModel.settings.preserveEXIF)

            Toggle("Include Location", isOn: $viewModel.settings.includeLocation)
                .disabled(!viewModel.settings.preserveEXIF)
        } header: {
            Text("Metadata")
        } footer: {
            Text("EXIF data includes camera settings, date taken, and other photo information.")
        }
    }

    private var destinationSection: some View {
        Section {
            Picker("Destination", selection: $viewModel.settings.destination) {
                ForEach(ExportDestination.allCases, id: \.self) { destination in
                    Label(destination.rawValue, systemImage: destination.iconName)
                        .tag(destination)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Destination")
        }
    }

    private var exportButtonSection: some View {
        Section {
            if viewModel.isExporting {
                exportProgressView
            } else {
                exportButton
            }
        } footer: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var exportButton: some View {
        Button(action: {
            viewModel.startExport()
        }) {
            HStack {
                Spacer()
                Label("Start Export", systemImage: "square.and.arrow.up")
                    .font(.headline)
                Spacer()
            }
        }
        .disabled(!viewModel.canStartExport)
    }

    private var exportProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.exportProgress) {
                Text(viewModel.progressText)
                    .font(.subheadline)
            }

            if viewModel.exportState.isActive {
                Button("Cancel Export", role: .destructive) {
                    viewModel.cancelExport()
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - State Handling

    private func handleStateChange(_ state: ExportState) {
        switch state {
        case .completed(let success, _):
            if viewModel.settings.destination == .share && success > 0 {
                showingShareSheet = true
            }
        default:
            break
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Complete View

/// View shown when export completes
struct ExportCompleteView: View {
    let successCount: Int
    let failureCount: Int
    let onDismiss: () -> Void
    let onViewFiles: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: failureCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(failureCount == 0 ? .green : .orange)

            // Status text
            VStack(spacing: 8) {
                Text(failureCount == 0 ? "Export Complete" : "Export Finished with Errors")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(successCount) photo\(successCount == 1 ? "" : "s") exported successfully")
                    .foregroundStyle(.secondary)

                if failureCount > 0 {
                    Text("\(failureCount) photo\(failureCount == 1 ? "" : "s") failed to export")
                        .foregroundStyle(.red)
                }
            }

            // Actions
            VStack(spacing: 12) {
                if let onViewFiles = onViewFiles {
                    Button(action: onViewFiles) {
                        Text("View Exported Files")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Done", action: onDismiss)
                    .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

// MARK: - Preview

#Preview("Export View") {
    ExportView(viewModel: ExportViewModel())
}

#Preview("Export Complete - Success") {
    ExportCompleteView(
        successCount: 5,
        failureCount: 0,
        onDismiss: {},
        onViewFiles: {}
    )
}

#Preview("Export Complete - With Errors") {
    ExportCompleteView(
        successCount: 3,
        failureCount: 2,
        onDismiss: {},
        onViewFiles: nil
    )
}
