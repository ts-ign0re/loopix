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

    /// Photo ID for saving edits back to ImportedPhotosManager
    var photoID: UUID?

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
                    // Navigation bar (hidden in tool detail mode and crop tab)
                    if showNavigationBar {
                        navigationBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Main content area
                    mainContent(geometry: geometry)

                    // Tab bar (hidden in detail modes)
                    if viewModel.showTabBar {
                        VSCOTabBar(selectedTab: $viewModel.selectedTab)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.mode)
                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
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

    /// Whether to show navigation bar (hidden in tool detail mode and crop tab)
    private var showNavigationBar: Bool {
        viewModel.mode.showNavigationBar && viewModel.selectedTab != .crop
    }

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
        guard let photoID = photoID else {
            // No photo ID - just dismiss (e.g., preview mode)
            dismiss()
            return
        }

        isSaving = true
        defer { isSaving = false }

        // Get current parameters from editor
        let parameters = viewModel.editor.currentParameters

        // Save parameters to ImportedPhotosManager
        ImportedPhotosManager.shared.updateEditedParameters(for: photoID, parameters: parameters)

        // Regenerate thumbnail with new parameters
        await ImportedPhotosManager.shared.regenerateThumbnail(for: photoID)

        // Notify gallery to reload
        NotificationCenter.default.post(name: .photoSavedFromEditor, object: nil)

        // Dismiss after successful save
        dismiss()
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
                // Image preview with histogram overlay (fills all available space)
                VSCOImagePreview(viewModel: viewModel)
                    .layoutPriority(1)

                // Tool panel based on selected tab (fixed height at bottom)
                toolPanel(geometry: geometry)
                    .fixedSize(horizontal: false, vertical: true)
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
        case .light, .effects:
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
        case .effects:
            return .effects
        }
    }
}

// MARK: - Preview

#Preview {
    EditorV2View(viewModel: EditorV2ViewModel())
}
