import SwiftUI
import CoreImage
import Photos

// MARK: - Adjust Category

/// Categories for grouping adjust tools
enum AdjustCategory: String, CaseIterable, Sendable {
    case exposure = "exposure"
    case highlights = "light"
    case levels = "levels"
    case whiteBalance = "color"
    case saturation = "tone"

    var displayName: String { rawValue }
}

// MARK: - Effect Category

/// Categories for grouping effect tools
enum EffectCategory: String, CaseIterable, Sendable {
    case clarity = "clarity"
    case sharpen = "sharpen"
    case grain = "grain"
    case fade = "fade"
    case vignette = "vignette"
    case bloom = "bloom"
    case halation = "halation"

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

// MARK: - Crop Mode

enum CropMode: String, CaseIterable {
    case transform
    case ratio
}

// MARK: - Crop Aspect Ratio

enum CropAspectRatio: String, CaseIterable {
    case free = "Free"
    case square = "1:1"
    case fourThree = "4:3"
    case threeTwo = "3:2"
    case sixteenNine = "16:9"
    case nineSixteen = "9:16"

    var displayName: String { rawValue }

    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .threeTwo: return 3.0 / 2.0
        case .sixteenNine: return 16.0 / 9.0
        case .nineSixteen: return 9.0 / 16.0
        }
    }

    var previewShape: some Shape {
        switch self {
        case .free: return AnyShape(Rectangle())
        case .square: return AnyShape(Rectangle())
        case .fourThree: return AnyShape(Rectangle())
        case .threeTwo: return AnyShape(Rectangle())
        case .sixteenNine: return AnyShape(Rectangle())
        case .nineSixteen: return AnyShape(Rectangle())
        }
    }
}

struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
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
        .task {
            // Wait for image to load, then sync crop rect
            while viewModel.isLoading {
                try? await Task.sleep(for: .milliseconds(50))
            }
            syncCropRectFromParameters()
        }
        .sheet(isPresented: $showFilterEditor) {
            FilterEditorView(
                filter: nil,
                onSave: { savedFilter in
                    Task {
                        await loadFilters()
                        viewModel.selectedPreset = savedFilter
                    }
                }
            )
        }
    }

    /// Sync interactiveCropRect from loaded FilterParameters
    private func syncCropRectFromParameters() {
        guard let imageSize = viewModel.originalImage?.extent.size,
              let cropRect = viewModel.currentParameters.cropRect else {
            // No crop set - use full image
            interactiveCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            return
        }

        // Convert from image coordinates to normalized (0-1)
        interactiveCropRect = CGRect(
            x: cropRect.origin.x / imageSize.width,
            y: cropRect.origin.y / imageSize.height,
            width: cropRect.width / imageSize.width,
            height: cropRect.height / imageSize.height
        )
    }

    // MARK: - Navigation Bar Items

    private var cancelButton: some View {
        Button {
            handleCancel()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
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
                ApertureLoader(size: 20, color: .white)
            }
        }
    }

    private var doneButton: some View {
        Button {
            handleDone()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(viewModel.hasChanges ? .yellow : Color(white: 0.4))
        }
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
                ZStack {
                    ImagePreview(
                        image: image,
                        zoomScale: $viewModel.zoomScale,
                        panOffset: $viewModel.panOffset
                    )
                    .frame(maxWidth: .infinity, maxHeight: previewHeight)
                    .clipped()

                    // Show crop overlay when crop tab is selected
                    if viewModel.selectedTab == .crop, let imageSize = viewModel.originalImage?.extent.size {
                        GeometryReader { geo in
                            SimpleCropOverlay(
                                cropRect: $interactiveCropRect,
                                aspectRatio: selectedAspectRatio.ratio,
                                imageSize: imageSize,
                                viewSize: geo.size
                            )
                        }
                        .onChange(of: interactiveCropRect) { _, newRect in
                            // Convert normalized rect to image coordinates
                            if let imageSize = viewModel.originalImage?.extent.size {
                                let imageRect = CGRect(
                                    x: newRect.origin.x * imageSize.width,
                                    y: newRect.origin.y * imageSize.height,
                                    width: newRect.width * imageSize.width,
                                    height: newRect.height * imageSize.height
                                )
                                viewModel.currentParameters.cropRect = imageRect
                                viewModel.schedulePreviewUpdatePublic()
                            }
                        }
                    }
                }
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
            }
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.95))
    }

    // MARK: - Filter State

    @State private var selectedFilterCategory: FilterCategory = .all
    @State private var availableFilters: [FilterPreset] = []
    // filterIntensity is now managed by viewModel (two-layer architecture)
    @State private var userPresets: [FilterPreset] = []
    @State private var favoriteIDs: Set<UUID> = []
    @State private var showFilterEditor = false

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
                    // Add button (only in MY category)
                    if selectedFilterCategory == .custom {
                        addFilterButton
                    }

                    // Original (no filter)
                    filterPresetCell(FilterPreset.original)

                    // Available filters
                    ForEach(availableFilters) { preset in
                        filterPresetCell(preset)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }

            // Intensity slider (shown when a filter is selected)
            if viewModel.selectedPreset != nil && viewModel.selectedPreset?.id != FilterPreset.original.id {
                HStack(spacing: 12) {
                    Text("intensity")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))

                    Slider(value: Binding(
                        get: { viewModel.filterIntensity },
                        set: { viewModel.setFilterIntensity($0) }
                    ), in: 0...100)
                    .tint(.yellow)

                    Text("\(Int(viewModel.filterIntensity))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
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
        // Load user presets
        userPresets = await FilterStorage.shared.getUserPresets()

        // Load favorites from UserDefaults
        if let savedIDs = UserDefaults.standard.array(forKey: "favoriteFilterIDs") as? [String] {
            favoriteIDs = Set(savedIDs.compactMap { UUID(uuidString: $0) })
        }

        // Get all built-in presets
        let allBuiltIn = FilmEmulations.all + CreativeFilters.all + FujiRecipes.all
        let allFilters = allBuiltIn + userPresets

        // Filter by category
        let filtered: [FilterPreset]
        switch selectedFilterCategory {
        case .favorites:
            filtered = allFilters.filter { favoriteIDs.contains($0.id) }
        case .custom:
            filtered = userPresets
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
        case .creative:
            filtered = []
        case .fujiRecipes:
            filtered = FujiRecipes.all
        }

        availableFilters = filtered
    }

    private func filterCategoryTab(_ category: FilterCategory) -> some View {
        let isSelected = selectedFilterCategory == category
        let isFavorites = category == .favorites

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilterCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                if isFavorites {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isSelected ? .yellow : .yellow.opacity(0.8))
                }
                Text(category.displayName)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .yellow : .white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isSelected ? Color.white.opacity(0.1) : Color.clear
            )
            .clipShape(Capsule())
        }
    }

    /// Add filter button for MY category
    private var addFilterButton: some View {
        Button {
            showFilterEditor = true
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 72, height: 72)

                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }

                Text("New")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
    }

    /// Toggle favorite status for a filter
    private func toggleFavorite(_ preset: FilterPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if favoriteIDs.contains(preset.id) {
                favoriteIDs.remove(preset.id)
            } else {
                favoriteIDs.insert(preset.id)
            }
        }

        // Persist to UserDefaults
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func filterPresetCell(_ preset: FilterPreset) -> some View {
        let isSelected = viewModel.selectedPreset?.id == preset.id ||
            (preset.id == FilterPreset.original.id && viewModel.selectedPreset == nil)
        let isFavorite = favoriteIDs.contains(preset.id)
        let isOriginal = preset.id == FilterPreset.original.id

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isOriginal {
                    viewModel.selectedPreset = nil
                    viewModel.resetToOriginal()
                } else {
                    // filterIntensity is set automatically by viewModel.selectedPreset.didSet
                    viewModel.selectedPreset = preset
                }
            }
        } label: {
            VStack(spacing: 4) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))

                    if viewModel.currentImage != nil {
                        // Show a preview of the filter applied to thumbnail
                        FilterThumbnailView(
                            baseImage: viewModel.originalImage,
                            preset: isOriginal ? nil : preset
                        )
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: preset.category.iconName)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    // Favorite indicator
                    if isFavorite && !isOriginal {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(4)
                            .background(Circle().fill(.black.opacity(0.5)))
                            .padding(4)
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
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? .yellow : .white.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !isOriginal {
                        toggleFavorite(preset)
                    }
                }
        )
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
                .font(.system(.subheadline, design: .monospaced).weight(adjustCategory == category ? .semibold : .regular))
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
                defaultValue: 0,
                valueFormat: "%.1f",
                step: 0.1
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
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EffectCategory.allCases, id: \.self) { category in
                        effectCategoryTab(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Sliders for selected category
            VStack(spacing: 6) {
                effectSlidersForCategory(effectCategory)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func effectCategoryTab(_ category: EffectCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                effectCategory = category
            }
        } label: {
            Text(category.displayName)
                .font(.system(.subheadline, design: .monospaced).weight(effectCategory == category ? .semibold : .regular))
                .foregroundStyle(effectCategory == category ? .yellow : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    effectCategory == category ?
                    Color.white.opacity(0.1) : Color.clear
                )
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func effectSlidersForCategory(_ category: EffectCategory) -> some View {
        switch category {
        case .clarity:
            ToolSlider(
                label: "Amount",
                value: Binding(
                    get: { viewModel.currentParameters.clarity },
                    set: { viewModel.updateParameter(\.clarity, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
        case .sharpen:
            ToolSlider(
                label: "Amount",
                value: Binding(
                    get: { viewModel.currentParameters.sharpness },
                    set: { viewModel.updateParameter(\.sharpness, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Radius",
                value: Binding(
                    get: { viewModel.currentParameters.sharpenRadius },
                    set: { viewModel.updateParameter(\.sharpenRadius, value: $0) }
                ),
                range: 0.5...3.0,
                defaultValue: 1.0
            )
        case .grain:
            ToolSlider(
                label: "Amount",
                value: Binding(
                    get: { viewModel.currentParameters.grain.amount },
                    set: { viewModel.updateParameter(\.grain.amount, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Size",
                value: Binding(
                    get: { viewModel.currentParameters.grain.size },
                    set: { viewModel.updateParameter(\.grain.size, value: $0) }
                ),
                range: 0...1,
                defaultValue: 0.5
            )
        case .fade:
            ToolSlider(
                label: "Amount",
                value: Binding(
                    get: { viewModel.currentParameters.fade },
                    set: { viewModel.updateParameter(\.fade, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
        case .vignette:
            ToolSlider(
                label: "Amount",
                value: Binding(
                    get: { viewModel.currentParameters.vignette.amount },
                    set: { viewModel.updateParameter(\.vignette.amount, value: $0) }
                ),
                range: -100...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Feather",
                value: Binding(
                    get: { viewModel.currentParameters.vignette.feather },
                    set: { viewModel.updateParameter(\.vignette.feather, value: $0) }
                ),
                range: 0...1,
                defaultValue: 0.5
            )
        case .bloom:
            ToolSlider(
                label: "Intensity",
                value: Binding(
                    get: { viewModel.currentParameters.bloom.intensity },
                    set: { viewModel.updateParameter(\.bloom.intensity, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Radius",
                value: Binding(
                    get: { viewModel.currentParameters.bloom.radius },
                    set: { viewModel.updateParameter(\.bloom.radius, value: $0) }
                ),
                range: 0...1,
                defaultValue: 0.5
            )
        case .halation:
            ToolSlider(
                label: "Intensity",
                value: Binding(
                    get: { viewModel.currentParameters.halation.intensity },
                    set: { viewModel.updateParameter(\.halation.intensity, value: $0) }
                ),
                range: 0...100,
                defaultValue: 0
            )
            ToolSlider(
                label: "Spread",
                value: Binding(
                    get: { viewModel.currentParameters.halation.spread },
                    set: { viewModel.updateParameter(\.halation.spread, value: $0) }
                ),
                range: 0...1,
                defaultValue: 0.5
            )
        }
    }

    // Crop state
    @State private var selectedAspectRatio: CropAspectRatio = .free
    @State private var cropMode: CropMode = .transform
    @State private var interactiveCropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var savedCropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var hasPendingCrop: Bool = false

    /// Check if current crop differs from saved
    private var cropHasChanges: Bool {
        interactiveCropRect != savedCropRect
    }

    private var cropToolPanel: some View {
        VStack(spacing: 0) {
            // Apply / Revert buttons at top
            HStack(spacing: 12) {
                // Revert button
                Button {
                    revertCrop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .medium))
                        Text("revert")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(cropHasChanges ? .white : .white.opacity(0.3))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(cropHasChanges ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .disabled(!cropHasChanges)

                // Apply button
                Button {
                    applyCrop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("apply")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(cropHasChanges ? .black : .black.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(cropHasChanges ? Color.yellow : Color.yellow.opacity(0.3))
                    )
                }
                .disabled(!cropHasChanges)
            }
            .padding(.vertical, 12)

            Divider()
                .background(Color.white.opacity(0.1))

            // Mode selector
            HStack(spacing: 16) {
                cropModeButton(mode: .transform, label: "transform")
                cropModeButton(mode: .ratio, label: "aspect ratio")
            }
            .padding(.vertical, 8)

            if cropMode == .transform {
                // Transform tools
                HStack(spacing: 0) {
                    cropToolButton(icon: "rotate.left", label: "rotate l", isActive: false) {
                        viewModel.rotateLeft()
                    }
                    cropToolButton(icon: "rotate.right", label: "rotate r", isActive: false) {
                        viewModel.rotateRight()
                    }
                    cropToolButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: "flip h", isActive: viewModel.currentParameters.flipHorizontal) {
                        viewModel.flipHorizontal()
                    }
                    cropToolButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", label: "flip v", isActive: viewModel.currentParameters.flipVertical) {
                        viewModel.flipVertical()
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // Aspect ratio selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CropAspectRatio.allCases, id: \.self) { ratio in
                            aspectRatioButton(ratio)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func applyCrop() {
        savedCropRect = interactiveCropRect
        hasPendingCrop = false

        // Update the preview
        viewModel.schedulePreviewUpdatePublic()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func revertCrop() {
        interactiveCropRect = savedCropRect

        // Reset crop rect in parameters
        if savedCropRect == CGRect(x: 0, y: 0, width: 1, height: 1) {
            viewModel.currentParameters.cropRect = nil
        } else if let imageSize = viewModel.originalImage?.extent.size {
            viewModel.currentParameters.cropRect = CGRect(
                x: savedCropRect.origin.x * imageSize.width,
                y: savedCropRect.origin.y * imageSize.height,
                width: savedCropRect.width * imageSize.width,
                height: savedCropRect.height * imageSize.height
            )
        }

        selectedAspectRatio = .free
        viewModel.schedulePreviewUpdatePublic()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func cropModeButton(mode: CropMode, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                cropMode = mode
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: cropMode == mode ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(cropMode == mode ? .yellow : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(cropMode == mode ? Color.white.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
        }
    }

    private func cropToolButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(isActive ? Color.yellow.opacity(0.2) : Color.clear)
                    .clipShape(Circle())
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(isActive ? .yellow : .white.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
    }

    private func aspectRatioButton(_ ratio: CropAspectRatio) -> some View {
        let isSelected = selectedAspectRatio == ratio
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAspectRatio = ratio
                applyCropAspectRatio(ratio)
            }
        } label: {
            VStack(spacing: 4) {
                ratio.previewShape
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Color.yellow.opacity(0.1) : Color.clear)
                Text(ratio.displayName.lowercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(isSelected ? .yellow : .white.opacity(0.7))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func applyCropAspectRatio(_ ratio: CropAspectRatio) {
        guard let imageSize = viewModel.originalImage?.extent.size else { return }

        if ratio == .free {
            // Reset to full image for free crop
            interactiveCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            viewModel.currentParameters.cropRect = nil
            viewModel.schedulePreviewUpdatePublic()
            return
        }

        guard let aspectRatio = ratio.ratio else { return }

        let imageAspect = imageSize.width / imageSize.height
        var normalizedRect: CGRect

        if aspectRatio > imageAspect {
            // Crop height
            let normalizedHeight = imageAspect / aspectRatio
            let yOffset = (1.0 - normalizedHeight) / 2
            normalizedRect = CGRect(x: 0, y: yOffset, width: 1, height: normalizedHeight)
        } else {
            // Crop width
            let normalizedWidth = aspectRatio / imageAspect
            let xOffset = (1.0 - normalizedWidth) / 2
            normalizedRect = CGRect(x: xOffset, y: 0, width: normalizedWidth, height: 1)
        }

        // Update interactive crop rect (normalized 0-1)
        interactiveCropRect = normalizedRect

        // Convert to image coordinates for FilterParameters
        let imageRect = CGRect(
            x: normalizedRect.origin.x * imageSize.width,
            y: normalizedRect.origin.y * imageSize.height,
            width: normalizedRect.width * imageSize.width,
            height: normalizedRect.height * imageSize.height
        )
        viewModel.currentParameters.cropRect = imageRect
        viewModel.schedulePreviewUpdatePublic()
    }

    // MARK: - Tab Bar Section

    private var tabBarSection: some View {
        HStack(spacing: 2) {
            ForEach(EditorTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: EditorTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24, height: 24)

                Text(tab.rawValue)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(viewModel.selectedTab == tab ? .yellow : Color(white: 0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(viewModel.selectedTab == tab ? Color.yellow.opacity(0.15) : Color.clear)
            )
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

                // Save to ImportedPhotosManager if we have a photoID
                if let photoID = photoID {
                    ImportedPhotosManager.shared.updateEditedParameters(
                        for: photoID,
                        parameters: viewModel.currentParameters
                    )
                    // Regenerate thumbnail with new parameters
                    await ImportedPhotosManager.shared.regenerateThumbnail(for: photoID)
                }

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

// MARK: - Simple Crop Overlay

/// A simple crop overlay that shows the crop region with handles
private struct SimpleCropOverlay: View {
    @Binding var cropRect: CGRect
    let aspectRatio: CGFloat?
    let imageSize: CGSize
    let viewSize: CGSize

    @State private var dragStart: CGPoint = .zero
    @State private var initialRect: CGRect = .zero
    @State private var activeEdge: Edge?

    enum Edge {
        case top, bottom, left, right
        case topLeft, topRight, bottomLeft, bottomRight
        case center
    }

    var body: some View {
        let scale = calculateScale()
        let offset = calculateOffset(scale: scale)
        let displayRect = cropRectInViewCoordinates(scale: scale, offset: offset)

        ZStack {
            // Darkened overlay outside crop area
            darkenedOverlay(displayRect: displayRect)

            // Crop frame with rule of thirds grid
            cropFrame(displayRect: displayRect)

            // Corner handles
            cornerHandles(displayRect: displayRect, scale: scale)
        }
    }

    // MARK: - Darkened Overlay

    private func darkenedOverlay(displayRect: CGRect) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: viewSize))
            path.addRect(displayRect)
        }
        .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    // MARK: - Crop Frame

    private func cropFrame(displayRect: CGRect) -> some View {
        ZStack {
            // Main border
            Rectangle()
                .strokeBorder(Color.white, lineWidth: 1.5)
                .frame(width: displayRect.width, height: displayRect.height)
                .position(x: displayRect.midX, y: displayRect.midY)

            // Rule of thirds grid
            ForEach([1, 2], id: \.self) { i in
                // Vertical lines
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 0.5, height: displayRect.height)
                    .position(
                        x: displayRect.minX + displayRect.width * CGFloat(i) / 3,
                        y: displayRect.midY
                    )

                // Horizontal lines
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: displayRect.width, height: 0.5)
                    .position(
                        x: displayRect.midX,
                        y: displayRect.minY + displayRect.height * CGFloat(i) / 3
                    )
            }

            // Center drag area
            Rectangle()
                .fill(Color.clear)
                .frame(width: max(displayRect.width - 80, 40), height: max(displayRect.height - 80, 40))
                .contentShape(Rectangle())
                .position(x: displayRect.midX, y: displayRect.midY)
                .gesture(centerDragGesture(scale: calculateScale()))
        }
        .allowsHitTesting(true)
    }

    // MARK: - Corner Handles

    private func cornerHandles(displayRect: CGRect, scale: CGFloat) -> some View {
        let handleLength: CGFloat = 20
        let handleWidth: CGFloat = 3

        return ZStack {
            // Top-Left
            cornerHandle(at: CGPoint(x: displayRect.minX, y: displayRect.minY),
                        edge: .topLeft, length: handleLength, width: handleWidth, scale: scale)

            // Top-Right
            cornerHandle(at: CGPoint(x: displayRect.maxX, y: displayRect.minY),
                        edge: .topRight, length: handleLength, width: handleWidth, scale: scale)

            // Bottom-Left
            cornerHandle(at: CGPoint(x: displayRect.minX, y: displayRect.maxY),
                        edge: .bottomLeft, length: handleLength, width: handleWidth, scale: scale)

            // Bottom-Right
            cornerHandle(at: CGPoint(x: displayRect.maxX, y: displayRect.maxY),
                        edge: .bottomRight, length: handleLength, width: handleWidth, scale: scale)
        }
    }

    private func cornerHandle(at position: CGPoint, edge: Edge, length: CGFloat, width: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            // L-shaped corner
            Path { path in
                switch edge {
                case .topLeft:
                    path.move(to: CGPoint(x: 0, y: length))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: length, y: 0))
                case .topRight:
                    path.move(to: CGPoint(x: -length, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: length))
                case .bottomLeft:
                    path.move(to: CGPoint(x: 0, y: -length))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: length, y: 0))
                case .bottomRight:
                    path.move(to: CGPoint(x: -length, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: -length))
                default:
                    break
                }
            }
            .stroke(Color.white, lineWidth: width)
            .position(position)

            // Hit area
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .position(position)
                .gesture(cornerDragGesture(edge: edge, scale: scale))
        }
    }

    // MARK: - Gestures

    private func cornerDragGesture(edge: Edge, scale: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if activeEdge == nil {
                    activeEdge = edge
                    initialRect = cropRect
                    dragStart = value.startLocation
                }
                handleCornerDrag(value: value, edge: edge, scale: scale)
            }
            .onEnded { _ in
                activeEdge = nil
            }
    }

    private func centerDragGesture(scale: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if activeEdge == nil {
                    activeEdge = .center
                    initialRect = cropRect
                    dragStart = value.startLocation
                }
                handleCenterDrag(value: value, scale: scale)
            }
            .onEnded { _ in
                activeEdge = nil
            }
    }

    private func handleCornerDrag(value: DragGesture.Value, edge: Edge, scale: CGFloat) {
        let delta = CGPoint(
            x: (value.location.x - dragStart.x) / scale / imageSize.width,
            y: (value.location.y - dragStart.y) / scale / imageSize.height
        )

        var newRect = initialRect
        let minSize: CGFloat = 0.1

        switch edge {
        case .topLeft:
            newRect.origin.x = min(initialRect.origin.x + delta.x, initialRect.maxX - minSize)
            newRect.origin.y = min(initialRect.origin.y + delta.y, initialRect.maxY - minSize)
            newRect.size.width = initialRect.maxX - newRect.origin.x
            newRect.size.height = initialRect.maxY - newRect.origin.y

        case .topRight:
            newRect.origin.y = min(initialRect.origin.y + delta.y, initialRect.maxY - minSize)
            newRect.size.width = max(initialRect.width + delta.x, minSize)
            newRect.size.height = initialRect.maxY - newRect.origin.y

        case .bottomLeft:
            newRect.origin.x = min(initialRect.origin.x + delta.x, initialRect.maxX - minSize)
            newRect.size.width = initialRect.maxX - newRect.origin.x
            newRect.size.height = max(initialRect.height + delta.y, minSize)

        case .bottomRight:
            newRect.size.width = max(initialRect.width + delta.x, minSize)
            newRect.size.height = max(initialRect.height + delta.y, minSize)

        default:
            break
        }

        // Maintain aspect ratio if set
        if let aspect = aspectRatio {
            let imageAspect = imageSize.width / imageSize.height
            let targetAspect = aspect / imageAspect

            if newRect.width / newRect.height > targetAspect {
                newRect.size.height = newRect.width / targetAspect
            } else {
                newRect.size.width = newRect.height * targetAspect
            }
        }

        // Clamp to bounds
        newRect.origin.x = max(0, min(newRect.origin.x, 1 - newRect.width))
        newRect.origin.y = max(0, min(newRect.origin.y, 1 - newRect.height))
        newRect.size.width = min(newRect.width, 1 - newRect.origin.x)
        newRect.size.height = min(newRect.height, 1 - newRect.origin.y)

        cropRect = newRect
    }

    private func handleCenterDrag(value: DragGesture.Value, scale: CGFloat) {
        let delta = CGPoint(
            x: (value.location.x - dragStart.x) / scale / imageSize.width,
            y: (value.location.y - dragStart.y) / scale / imageSize.height
        )

        var newRect = initialRect
        newRect.origin.x = initialRect.origin.x + delta.x
        newRect.origin.y = initialRect.origin.y + delta.y

        // Clamp to bounds
        newRect.origin.x = max(0, min(newRect.origin.x, 1 - newRect.width))
        newRect.origin.y = max(0, min(newRect.origin.y, 1 - newRect.height))

        cropRect = newRect
    }

    // MARK: - Coordinate Conversion

    private func calculateScale() -> CGFloat {
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        return min(scaleX, scaleY)
    }

    private func calculateOffset(scale: CGFloat) -> CGPoint {
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        return CGPoint(
            x: (viewSize.width - scaledWidth) / 2,
            y: (viewSize.height - scaledHeight) / 2
        )
    }

    private func cropRectInViewCoordinates(scale: CGFloat, offset: CGPoint) -> CGRect {
        CGRect(
            x: offset.x + cropRect.origin.x * imageSize.width * scale,
            y: offset.y + cropRect.origin.y * imageSize.height * scale,
            width: cropRect.width * imageSize.width * scale,
            height: cropRect.height * imageSize.height * scale
        )
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
