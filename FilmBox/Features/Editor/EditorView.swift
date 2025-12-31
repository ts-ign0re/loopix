import SwiftUI
import CoreImage

// MARK: - Editor View

/// Main editor screen for photo editing
struct EditorView: View {

    // MARK: - Properties

    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    /// Callback when editing is cancelled
    var onCancel: (() -> Void)?

    /// Callback when editing is completed with the result
    var onDone: ((CIImage) -> Void)?

    // MARK: - Initialization

    init(image: CIImage, onCancel: (() -> Void)? = nil, onDone: ((CIImage) -> Void)? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(image: image))
        self.onCancel = onCancel
        self.onDone = onDone
    }

    init(uiImage: UIImage, onCancel: (() -> Void)? = nil, onDone: ((CIImage) -> Void)? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(uiImage: uiImage))
        self.onCancel = onCancel
        self.onDone = onDone
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Image Preview Area
                    imagePreviewSection(geometry: geometry)

                    // Histogram (optional, shown when space allows)
                    if geometry.size.height > 600 {
                        histogramSection
                    }

                    // Tool Panel
                    toolPanelSection

                    // Tab Bar
                    tabBarSection
                }
                .background(Color.black)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }

                ToolbarItem(placement: .principal) {
                    titleView
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Navigation Bar Items

    private var cancelButton: some View {
        Button("Cancel") {
            handleCancel()
        }
        .foregroundStyle(.white)
    }

    private var titleView: some View {
        HStack(spacing: 12) {
            if viewModel.canUndo {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.white)
            }

            if viewModel.canRedo {
                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.white)
            }

            if viewModel.isProcessing {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
            }
        }
    }

    private var doneButton: some View {
        Button("Done") {
            handleDone()
        }
        .fontWeight(.semibold)
        .foregroundStyle(viewModel.hasChanges ? .yellow : .white.opacity(0.5))
        .disabled(!viewModel.hasChanges)
    }

    // MARK: - Image Preview Section

    @ViewBuilder
    private func imagePreviewSection(geometry: GeometryProxy) -> some View {
        let previewHeight = geometry.size.height * 0.55

        ZStack {
            Color.black

            if let image = viewModel.isShowingOriginal ? viewModel.originalImage : viewModel.currentImage {
                ImagePreview(
                    image: image,
                    zoomScale: $viewModel.zoomScale,
                    panOffset: $viewModel.panOffset
                )
                .frame(maxWidth: .infinity, maxHeight: previewHeight)
                .clipped()
            } else {
                ContentUnavailableView {
                    Label("No Image", systemImage: "photo")
                } description: {
                    Text("Load an image to start editing")
                }
                .foregroundStyle(.white.opacity(0.6))
            }

            // Before/After indicator
            if viewModel.isShowingOriginal {
                VStack {
                    Text("ORIGINAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Spacer()
                }
                .padding(.top, 16)
            }
        }
        .frame(height: previewHeight)
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in
                    viewModel.isShowingOriginal = true
                }
                .onEnded { _ in
                    viewModel.isShowingOriginal = false
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    viewModel.isShowingOriginal = false
                }
        )
    }

    // MARK: - Histogram Section

    private var histogramSection: some View {
        HistogramView(viewModel: viewModel)
            .frame(height: 60)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    // MARK: - Tool Panel Section

    private var toolPanelSection: some View {
        VStack(spacing: 0) {
            switch viewModel.selectedTab {
            case .filters:
                filtersToolPanel
            case .adjust:
                adjustToolPanel
            case .effects:
                effectsToolPanel
            case .crop:
                cropToolPanel
            case .presets:
                presetsToolPanel
            }
        }
        .frame(height: 160)
        .background(Color.black.opacity(0.95))
    }

    // MARK: - Tool Panels

    private var filtersToolPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                // Filter thumbnails would go here
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    filterCategoryItem(category)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: .infinity)
    }

    private func filterCategoryItem(_ category: FilterCategory) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }

            Text(category.displayName)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var adjustToolPanel: some View {
        VStack(spacing: 12) {
            ToolSlider(
                label: "Exposure",
                value: Binding(
                    get: { viewModel.currentParameters.exposure },
                    set: { viewModel.updateExposure($0) }
                ),
                range: -2...2,
                defaultValue: 0
            )

            ToolSlider(
                label: "Contrast",
                value: Binding(
                    get: { viewModel.currentParameters.contrast },
                    set: { viewModel.updateContrast($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )

            ToolSlider(
                label: "Saturation",
                value: Binding(
                    get: { viewModel.currentParameters.saturation },
                    set: { viewModel.updateSaturation($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var effectsToolPanel: some View {
        VStack(spacing: 12) {
            ToolSlider(
                label: "Clarity",
                value: Binding(
                    get: { viewModel.currentParameters.clarity },
                    set: { viewModel.updateParameter(\.clarity, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )

            ToolSlider(
                label: "Vignette",
                value: Binding(
                    get: { viewModel.currentParameters.vignette.amount },
                    set: { viewModel.updateParameter(\.vignette.amount, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )

            ToolSlider(
                label: "Grain",
                value: Binding(
                    get: { viewModel.currentParameters.grain.amount },
                    set: { viewModel.updateParameter(\.grain.amount, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var cropToolPanel: some View {
        HStack(spacing: 24) {
            cropToolButton(icon: "rotate.left", label: "Rotate")
            cropToolButton(icon: "flip.horizontal", label: "Flip H")
            cropToolButton(icon: "flip.vertical", label: "Flip V")
            cropToolButton(icon: "aspectratio", label: "Aspect")
            cropToolButton(icon: "arrow.up.left.and.arrow.down.right", label: "Free")
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private func cropToolButton(icon: String, label: String) -> some View {
        Button {
            // Crop action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var presetsToolPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                // Preset thumbnails would go here
                ForEach(0..<10, id: \.self) { index in
                    presetItem(index: index)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: .infinity)
    }

    private func presetItem(index: Int) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 70, height: 70)
                .overlay {
                    Text("P\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                }

            Text("Preset \(index + 1)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
    }

    // MARK: - Tab Bar Section

    private var tabBarSection: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.black)
    }

    private func tabButton(for tab: EditorTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20))

                Text(tab.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(viewModel.selectedTab == tab ? .yellow : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleCancel() {
        if viewModel.hasChanges {
            // Could show confirmation alert here
        }
        onCancel?()
        dismiss()
    }

    private func handleDone() {
        Task {
            do {
                let result = try await viewModel.saveChanges()
                onDone?(result)
                dismiss()
            } catch {
                // Handle error
                print("Failed to save: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Editor View") {
    EditorView(uiImage: UIImage(systemName: "photo.fill")!)
}

#Preview("Editor - Dark Mode") {
    EditorView(uiImage: UIImage(systemName: "photo.artframe")!)
        .preferredColorScheme(.dark)
}
