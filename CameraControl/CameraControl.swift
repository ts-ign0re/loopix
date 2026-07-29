import SwiftUI
import WidgetKit

@main
struct CameraControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "loopix.truebloom.ltd.open-camera") {
            ControlWidgetButton(action: OpenCameraIntent()) {
                Label {
                    Text("Loopix Camera")
                } icon: {
                    Image("SplashLogo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                }
            }
        }
        .displayName("Loopix Camera")
        .description("Open the Loopix camera")
    }
}
