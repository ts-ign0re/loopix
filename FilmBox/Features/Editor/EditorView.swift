import SwiftUI
import CoreImage
import Photos

// MARK: - Adjust Category

/// Categories for grouping adjust tools
enum AdjustCategory: String, CaseIterable, Sendable {
    case exposure = "Exposure"
    case highlights = "Light"
    case levels = "Levels"
    case whiteBalance = "Color"
    case saturation = "Tone"

    var displayName: String { rawValue }
}

// MARK: - Effect Category

/// Categories for grouping effect tools
enum EffectCategory: String, CaseIterable, Sendable {
    case clarity = "Clarity"
    case sharpen = "Sharpen"
    case grain = "Grain"
    case fade = "Fade"
    case vignette = "Vignette"
    case bloom = "Bloom"
    case halation = "Halation"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .clarity: return "circle.hexagongrid"
        case .sharpen: return "triangle"
        case .grain: return "circle.dotted"
        case .fade: return "square.stack"
        case .vignette: return "circle.circle"
        case .bloom: return "sun.max"
        case .halation: return "light.max"
        }
    }
}

// MARK: - Editor View

/// Main editor screen for photo editing
struct EditorView: View {

    // MARK: - Properties

    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    /// Photo ID for saving edits back to ImportedPhotosManager
    private var photoID: UUID?

    /// Callback when editing is cancelled
    var onCancel: (() -> Void)?

    /// Callback when editing is completed with the result
    var onDone: ((CIImage) -> Void)?

    // MARK: - Initialization

    init(image: CIImage, onCancel: (() -> Void)? = nil, onDone: ((CIImage) -> Void)? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(image: image))
        self.photoID = nil
        self.onCancel = onCancel
        self.onDone = onDone
    }

    init(uiImage: UIImage, onCancel: (() -> Void)? = nil, onDone: ((CIImage) -> Void)? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(uiImage: uiImage))
        self.photoID = nil
        self.onCancel = onCancel
        self.onDone = onDone
    }

    /// Initialize with a PHAsset for editing from HomeView
    init(asset: PHAsset, photoID: UUID, initialParameters: FilterParameters? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(asset: asset, initialParameters: initialParameters))
        self.photoID = photoID
        self.onCancel = nil
        self.onDone = nil
    }

    /// Initialize with a CIImage and photoID for editing from local storage
    init(ciImage: CIImage, photoID: UUID, initialParameters: FilterParameters? = nil) {
        self._viewModel = State(initialValue: EditorViewModel(ciImage: ciImage, initialParameters: initialParameters))
        self.photoID = photoID
        self.onCancel = nil
        self.onDone = nil
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

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else if let image = viewModel.isShowingOriginal ? viewModel.originalImage : viewModel.currentImage {
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
        .frame(height: 200)
        .background(Color.black.opacity(0.95))
    }

    // MARK: - Filter State

    @State private var selectedFilterCategory: FilterCategory = .all
    @State private var availableFilters: [FilterPreset] = []
    @State private var filterIntensity: Float = 100

    // MARK: - Tool Panels

    private var filtersToolPanel: some View {
        VStack(spacing: 0) {
            // Category bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterCategory.allCases, id: \.self) { category in
                        filterCategoryTab(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            // Filter strip
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    // Original (no filter)
                    filterPresetCell(FilterPreset.original)

                    // Available filters
                    ForEach(availableFilters) { preset in
                        filterPresetCell(preset)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Intensity slider (shown when a filter is selected)
            if viewModel.selectedPreset != nil && viewModel.selectedPreset?.id != FilterPreset.original.id {
                HStack(spacing: 12) {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Slider(value: Binding(
                        get: { filterIntensity },
                        set: { newValue in
                            filterIntensity = newValue
                            if let preset = viewModel.selectedPreset {
                                viewModel.applyPreset(preset, intensity: filterIntensity)
                            }
                        }
                    ), in: 0...100)
                    .tint(.yellow)

                    Text("\(Int(filterIntensity))%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
        .task {
            await loadFilters()
        }
        .onChange(of: selectedFilterCategory) { _, _ in
            Task {
                await loadFilters()
            }
        }
    }

    private func loadFilters() async {
        // Get all built-in presets
        let allFilters = FilmEmulations.all + CreativeFilters.all

        // Filter by category
        let filtered: [FilterPreset]
        switch selectedFilterCategory {
        case .all:
            filtered = allFilters
        case .film:
            filtered = FilmEmulations.all
        case .cool:
            filtered = CreativeFilters.cool
        case .warm:
            filtered = CreativeFilters.warm
        case .pro:
            filtered = CreativeFilters.pro
        case .portrait:
            filtered = CreativeFilters.portrait
        case .urban:
            filtered = CreativeFilters.urban
        case .vintage:
            filtered = CreativeFilters.vintage
        case .bw:
            filtered = FilmEmulations.blackAndWhite
        case .custom, .creative:
            filtered = []
        }

        availableFilters = filtered
    }

    private func filterCategoryTab(_ category: FilterCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilterCategory = category
            }
        } label: {
            Text(category.displayName)
                .font(.caption.weight(selectedFilterCategory == category ? .semibold : .regular))
                .foregroundStyle(selectedFilterCategory == category ? .yellow : .white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    selectedFilterCategory == category ?
                    Color.white.opacity(0.1) : Color.clear
                )
                .clipShape(Capsule())
        }
    }

    private func filterPresetCell(_ preset: FilterPreset) -> some View {
        let isSelected = viewModel.selectedPreset?.id == preset.id ||
            (preset.id == FilterPreset.original.id && viewModel.selectedPreset == nil)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if preset.id == FilterPreset.original.id {
                    viewModel.selectedPreset = nil
                    viewModel.resetToOriginal()
                } else {
                    filterIntensity = 100
                    viewModel.selectedPreset = preset
                }
            }
        } label: {
            VStack(spacing: 4) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 72, height: 72)

                    if viewModel.currentImage != nil {
                        // Show a preview of the filter applied to thumbnail
                        FilterThumbnailView(
                            baseImage: viewModel.originalImage,
                            preset: preset.id == FilterPreset.original.id ? nil : preset
                        )
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: preset.category.iconName)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow, lineWidth: 2)
                    }
                }

                // Name
                Text(preset.name)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .yellow : .white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
    }

    // Adjust sub-categories
    @State private var adjustCategory: AdjustCategory = .exposure

    // Effect sub-categories
    @State private var effectCategory: EffectCategory = .clarity

    private var adjustToolPanel: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AdjustCategory.allCases, id: \.self) { category in
                        adjustCategoryTab(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Sliders for selected category
            VStack(spacing: 6) {
                adjustSlidersForCategory(adjustCategory)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func adjustCategoryTab(_ category: AdjustCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                adjustCategory = category
            }
        } label: {
            Text(category.displayName)
                .font(.subheadline.weight(adjustCategory == category ? .semibold : .regular))
                .foregroundStyle(adjustCategory == category ? .yellow : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    adjustCategory == category ?
                    Color.white.opacity(0.1) : Color.clear
                )
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func adjustSlidersForCategory(_ category: AdjustCategory) -> some View {
        switch category {
        case .exposure:
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
        case .highlights:
            ToolSlider(
                label: "Highlights",
                value: Binding(
                    get: { viewModel.currentParameters.highlights },
                    set: { viewModel.updateHighlights($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Shadows",
                value: Binding(
                    get: { viewModel.currentParameters.shadows },
                    set: { viewModel.updateShadows($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        case .levels:
            ToolSlider(
                label: "Whites",
                value: Binding(
                    get: { viewModel.currentParameters.whites },
                    set: { viewModel.updateParameter(\.whites, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Blacks",
                value: Binding(
                    get: { viewModel.currentParameters.blacks },
                    set: { viewModel.updateParameter(\.blacks, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        case .whiteBalance:
            ToolSlider(
                label: "Temperature",
                value: Binding(
                    get: { viewModel.currentParameters.temperature },
                    set: { viewModel.updateTemperature($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Tint",
                value: Binding(
                    get: { viewModel.currentParameters.tint },
                    set: { viewModel.updateParameter(\.tint, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        case .saturation:
            ToolSlider(
                label: "Saturation",
                value: Binding(
                    get: { viewModel.currentParameters.saturation },
                    set: { viewModel.updateSaturation($0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Vibrance",
                value: Binding(
                    get: { viewModel.currentParameters.vibrance },
                    set: { viewModel.updateParameter(\.vibrance, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        }
    }

    private var effectsToolPanel: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Detail section
                Text("Detail")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                    label: "Sharpness",
                    value: Binding(
                        get: { viewModel.currentParameters.sharpness },
                        set: { viewModel.updateParameter(\.sharpness, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                Divider().background(Color.white.opacity(0.2))

                // Film effects section
                Text("Film Effects")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ToolSlider(
                    label: "Grain",
                    value: Binding(
                        get: { viewModel.currentParameters.grain.amount },
                        set: { viewModel.updateParameter(\.grain.amount, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Fade",
                    value: Binding(
                        get: { viewModel.currentParameters.fade },
                        set: { viewModel.updateParameter(\.fade, value: $0) }
                    ),
                    range: 0...100,
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
                    label: "Bloom",
                    value: Binding(
                        get: { viewModel.currentParameters.bloom.intensity },
                        set: { viewModel.updateParameter(\.bloom.intensity, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Halation",
                    value: Binding(
                        get: { viewModel.currentParameters.halation.intensity },
                        set: { viewModel.updateParameter(\.halation.intensity, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var cropToolPanel: some View {
        HStack {
            cropToolButton(icon: "rotate.left", label: "Rotate") {
                viewModel.rotateLeft()
            }

            Spacer()

            cropToolButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: "Flip H") {
                viewModel.flipHorizontal()
            }

            Spacer()

            cropToolButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", label: "Flip V") {
                viewModel.flipVertical()
            }

            Spacer()

            cropToolButton(icon: "aspectratio", label: "Ratio") {
                // Show aspect ratio picker
            }

            Spacer()

            cropToolButton(icon: "crop", label: "Free") {
                // Free crop mode
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private func cropToolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
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

// MARK: - Filter Thumbnail View

/// A view that displays a thumbnail with a filter applied
struct FilterThumbnailView: View {
    let baseImage: CIImage?
    let preset: FilterPreset?

    @State private var thumbnailImage: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .task(id: preset?.id) {
            await generateThumbnail()
        }
    }

    private func generateThumbnail() async {
        guard let image = baseImage else { return }

        // Scale down the image for thumbnail
        let scale = min(128.0 / image.extent.width, 128.0 / image.extent.height)
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Apply preset if available
        var processedImage = scaledImage
        if let preset = preset {
            processedImage = await applyPresetToImage(scaledImage, preset: preset)
        }

        // Render to UIImage
        let context = CIContext(options: [.useSoftwareRenderer: false])
        if let cgImage = context.createCGImage(processedImage, from: processedImage.extent) {
            await MainActor.run {
                self.thumbnailImage = UIImage(cgImage: cgImage)
            }
        }
    }

    private func applyPresetToImage(_ image: CIImage, preset: FilterPreset) async -> CIImage {
        var output = image
        let params = preset.parameters

        // Apply basic adjustments for thumbnail preview
        if params.exposure != 0 {
            if let filter = CIFilter(name: "CIExposureAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(params.exposure, forKey: kCIInputEVKey)
                output = filter.outputImage ?? output
            }
        }

        if params.contrast != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (params.contrast / 100.0), forKey: kCIInputContrastKey)
                output = filter.outputImage ?? output
            }
        }

        if params.saturation != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (params.saturation / 100.0), forKey: kCIInputSaturationKey)
                output = filter.outputImage ?? output
            }
        }

        if params.temperature != 0 || params.tint != 0 {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                let targetTemp = 6500 + (params.temperature * 30)
                filter.setValue(CIVector(x: CGFloat(targetTemp), y: CGFloat(params.tint)), forKey: "inputTargetNeutral")
                output = filter.outputImage ?? output
            }
        }

        return output
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
