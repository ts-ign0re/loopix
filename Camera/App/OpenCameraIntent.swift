import AppIntents

enum LoopixDestination: String, AppEnum {
    case camera

    static let typeDisplayRepresentation = TypeDisplayRepresentation("Loopix screens")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .camera: DisplayRepresentation(title: "Camera")
    ]
}

struct OpenCameraIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Camera"

    @Parameter(title: "Target")
    var target: LoopixDestination

    init() {
        target = .camera
    }
}
