import SwiftUI
import Photos

/// Notification posted when a photo is saved from the editor
extension Notification.Name {
    static let photoSavedFromEditor = Notification.Name("photoSavedFromEditor")
}

/// Main VSCO-style editor view
struct EditorV2View: View {
    @Bindable var viewModel: EditorV2ViewModel
    @Environment(\.dismiss) private var dismiss

    /// Optional PHAsset to load on appear
    var asset: PHAsset?

    /// State for save operation
    @State private var isSaving = false
    @State private var saveError: Error?
    @State private var showSaveError = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Navigation bar
                    navigationBar

                    // Main content area
                    mainContent(geometry: geometry)

                    // Tab bar (hidden in detail modes)
                    if viewModel.showTabBar {
                        VSCOTabBar(selectedTab: $viewModel.selectedTab)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let asset = asset {
                viewModel.loadAsset(asset)
            }
        }
    }

    // MARK: - Navigation Bar

    @State private var showDiscardAlert = false

    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            // Back button - always shows chevron, confirms discard if changes made
            Button {
                // TODO: Check if there are unsaved changes
                showDiscardAlert = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 44, height: 44)

            Spacer()

            // Save button - saves all changes and exits
            Button {
                Task {
                    await saveChanges()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                }
            }
            .foregroundColor(.white)
            .disabled(isSaving)
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .alert("discard changes?", isPresented: $showDiscardAlert) {
            Button("discard", role: .destructive) {
                dismiss()
            }
            Button("cancel", role: .cancel) {}
        }
        .alert("save error", isPresented: $showSaveError) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(saveError?.localizedDescription ?? "unknown error")
        }
    }

    // MARK: - Save Changes

    private func saveChanges() async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Get the processed image from the editor
            let processedImage = try await viewModel.editor.saveChanges()

            // Render to CGImage for saving
            let ciContext = CIContext(options: [.useSoftwareRenderer: false])
            guard let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent) else {
                throw EditorError.exportFailed
            }

            // Save to Photos library
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.95)!, options: nil)
            }

            // Notify gallery to reload
            NotificationCenter.default.post(name: .photoSavedFromEditor, object: nil)

            // Dismiss after successful save
            dismiss()
        } catch {
            saveError = error
            showSaveError = true
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        switch viewModel.mode {
        case .browse:
            browseContent(geometry: geometry)
        case .filterDetail:
            FilterDetailView(viewModel: viewModel, geometry: geometry)
        case .toolDetail(let tool):
            ToolDetailView(viewModel: viewModel, tool: tool, geometry: geometry)
        }
    }

    // MARK: - Browse Content

    @ViewBuilder
    private func browseContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // For crop tab, show full-screen crop view
            if viewModel.selectedTab == .crop {
                CropTabView(viewModel: viewModel, geometry: geometry)
            } else {
                // Image preview with histogram overlay (fills available space)
                VSCOImagePreview(viewModel: viewModel)

                // Tool panel based on selected tab (fixed at bottom)
                toolPanel(geometry: geometry)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Tool Panel

    @ViewBuilder
    private func toolPanel(geometry: GeometryProxy) -> some View {
        switch viewModel.selectedTab {
        case .filters:
            VSCOFiltersTabView(viewModel: viewModel)
        case .crop:
            EmptyView() // Handled in browseContent
        case .light, .color:
            VSCOToolsTabView(
                viewModel: viewModel,
                category: mapTabToCategory(viewModel.selectedTab)
            )
        }
    }

    private func mapTabToCategory(_ tab: EditorV2Tab) -> ToolDefinition.ToolCategory {
        switch tab {
        case .filters, .crop:
            return .all
        case .light:
            return .light
        case .color:
            return .color
        }
    }
}

// MARK: - Preview

#Preview {
    EditorV2View(viewModel: EditorV2ViewModel())
}
