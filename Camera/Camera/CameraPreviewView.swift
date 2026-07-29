import SwiftUI
import MetalKit

/// UIViewRepresentable wrapping MTKView for GPU-accelerated camera preview
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    let state: CameraState
    let filter: CameraFilter
    var onTapFocus: ((CGPoint) -> Void)?

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.backgroundColor = .black

        if let renderer = MetalPreviewRenderer(mtkView: mtkView) {
            context.coordinator.renderer = renderer
            mtkView.delegate = renderer
            cameraManager.previewFrameHandler = { [weak renderer, weak mtkView] image in
                renderer?.currentCIImage = image
                mtkView?.setNeedsDisplay()
            }
        }

        // Tap gesture for focus
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mtkView.addGestureRecognizer(tapGesture)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator.renderer else { return }
        renderer.currentFilter = filter
        renderer.filterIntensity = state.filterIntensity
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: CameraPreviewView
        var renderer: MetalPreviewRenderer?

        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            guard let view = gesture.view else { return }

            // Convert to normalized coordinates (0-1)
            let normalizedPoint = CGPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )

            parent.onTapFocus?(normalizedPoint)
        }
    }
}
