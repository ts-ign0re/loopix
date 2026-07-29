import SwiftUI
import WidgetKit

@main
struct CameraControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "loopix.truebloom.ltd.open-camera") {
            ControlWidgetButton(action: OpenCameraIntent()) {
                // Control Center renders only symbol images; raster assets fall back
                // to a questionmark glyph, so the logo ships as a custom symbolset.
                Label {
                    Text("Loopix Camera")
                } icon: {
                    Image("LoopixGlyph")
                }
            }
        }
        .displayName("Loopix Camera")
        .description("Open the Loopix camera")
    }
}
