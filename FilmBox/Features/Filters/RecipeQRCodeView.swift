import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation
import PhotosUI

// MARK: - Recipe QR Code View (Export)

@available(iOS 17.0, *)
struct RecipeQRCodeView: View {
    @Environment(\.dismiss) private var dismiss

    let filter: FilterPreset

    @State private var qrImage: UIImage?
    @State private var isGenerating = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Recipe name
                    Text(filter.name)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    // QR Code
                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .white.opacity(0.1), radius: 20)
                    } else if isGenerating {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 280, height: 280)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }

                    // Instructions
                    Text("scan this code with loopix\nto import the recipe")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)

                    // Share button
                    if let qrImage {
                        Button {
                            shareQRCode(qrImage)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("share")
                            }
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.yellow)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ export recipe")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await generateQRCode()
        }
    }

    // MARK: - QR Code Generation

    private func generateQRCode() async {
        isGenerating = true

        // Create compact recipe data for QR
        let recipeData = RecipeQRData(from: filter)

        guard let jsonData = try? JSONEncoder().encode(recipeData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            isGenerating = false
            return
        }

        // Generate QR code
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        filter.correctionLevel = "H" // High error correction for logo overlay

        guard let outputImage = filter.outputImage else {
            isGenerating = false
            return
        }

        // Scale up the QR code
        let scale: CGFloat = 10
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            isGenerating = false
            return
        }

        // Add Loopix logo overlay
        let finalImage = await addLogoToQRCode(cgImage)

        await MainActor.run {
            self.qrImage = finalImage
            self.isGenerating = false
        }
    }

    private func addLogoToQRCode(_ qrImage: CGImage) async -> UIImage {
        let size = CGSize(width: qrImage.width, height: qrImage.height)

        return await MainActor.run {
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { _ in
                // Draw QR code
                UIImage(cgImage: qrImage).draw(in: CGRect(origin: .zero, size: size))

                // Draw white rounded rect background for logo
                let logoWidth = size.width * 0.32
                let logoHeight = size.height * 0.18
                let logoRect = CGRect(
                    x: (size.width - logoWidth) / 2,
                    y: (size.height - logoHeight) / 2,
                    width: logoWidth,
                    height: logoHeight
                )

                // White rounded rect background with padding
                UIColor.white.setFill()
                let bgRect = logoRect.insetBy(dx: -logoWidth * 0.08, dy: -logoHeight * 0.12)
                let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: bgRect.height * 0.2)
                bgPath.fill()

                // Draw "loopix" and "ios" text
                drawLoopixText(in: logoRect)
            }
        }
    }

    private func drawLoopixText(in rect: CGRect) {
        // Draw "loopix" text
        let loopixFont = UIFont.systemFont(ofSize: rect.height * 0.52, weight: .bold)
        let loopixAttrs: [NSAttributedString.Key: Any] = [
            .font: loopixFont,
            .foregroundColor: UIColor.black
        ]
        let loopixText = "loopix"
        let loopixSize = loopixText.size(withAttributes: loopixAttrs)
        let loopixRect = CGRect(
            x: rect.midX - loopixSize.width / 2,
            y: rect.minY,
            width: loopixSize.width,
            height: loopixSize.height
        )
        loopixText.draw(in: loopixRect, withAttributes: loopixAttrs)

        // Draw "ios" text below
        let iosFont = UIFont.systemFont(ofSize: rect.height * 0.32, weight: .medium)
        let iosAttrs: [NSAttributedString.Key: Any] = [
            .font: iosFont,
            .foregroundColor: UIColor.darkGray
        ]
        let iosText = "ios"
        let iosSize = iosText.size(withAttributes: iosAttrs)
        let iosRect = CGRect(
            x: rect.midX - iosSize.width / 2,
            y: loopixRect.maxY - rect.height * 0.08,
            width: iosSize.width,
            height: iosSize.height
        )
        iosText.draw(in: iosRect, withAttributes: iosAttrs)
    }

    // MARK: - Share

    private func shareQRCode(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Recipe QR Data (Compact format for QR encoding)

struct RecipeQRData: Codable {
    let v: Int = 1  // Version
    let n: String   // Name
    let p: RecipeParams

    struct RecipeParams: Codable {
        // Light
        var exp: Float?     // exposure
        var con: Float?     // contrast
        var hig: Float?     // highlights
        var sha: Float?     // shadows
        var whi: Float?     // whites
        var bla: Float?     // blacks

        // Color
        var tem: Float?     // temperature
        var tin: Float?     // tint
        var sat: Float?     // saturation
        var vib: Float?     // vibrance

        // Skin tone
        var skH: Float?     // skin tone hue
        var skS: Float?     // skin tone saturation

        // HSL - 8 channels [R,O,Y,G,A,B,P,M] each with [h,s,l]
        var hsl: [[Float]]?

        // Split tone
        var stHH: Float?    // split tone highlight hue
        var stHS: Float?    // split tone highlight saturation
        var stSH: Float?    // split tone shadow hue
        var stSS: Float?    // split tone shadow saturation
        var stB: Float?     // split tone balance

        // Tone curve - [composite, red, green, blue] each is array of [x,y] points
        var tc: [[[Float]]]?

        // Effects
        var cla: Float?     // clarity
        var fad: Float?     // fade
        var shp: Float?     // sharpness
        var shR: Float?     // sharpen radius
        var noR: Float?     // noise reduction

        // Grain
        var grA: Float?     // grain amount
        var grS: Float?     // grain size
        var grR: Float?     // grain roughness
        var grM: Bool?      // grain monochromatic

        // Vignette
        var viA: Float?     // vignette amount
        var viM: Float?     // vignette midpoint
        var viR: Float?     // vignette roundness
        var viF: Float?     // vignette feather

        // Bloom
        var blI: Float?     // bloom intensity
        var blR: Float?     // bloom radius
        var blT: Float?     // bloom threshold

        // Halation
        var haI: Float?     // halation intensity
        var haH: Float?     // halation hue
        var haS: Float?     // halation spread

        // Fuji simulation
        var fsT: String?    // film simulation type
        var drM: String?    // dynamic range mode
        var ccE: String?    // color chrome effect
        var ccB: String?    // color chrome fx blue
        var wbR: Int?       // white balance red shift
        var wbB: Int?       // white balance blue shift
    }

    // swiftlint:disable:next cyclomatic_complexity
    init(from filter: FilterPreset) {
        self.n = filter.name

        let params = filter.parameters
        var p = RecipeParams()

        // Light - only include non-default values to minimize QR data
        if params.exposure != 0 { p.exp = params.exposure }
        if params.contrast != 0 { p.con = params.contrast }
        if params.highlights != 0 { p.hig = params.highlights }
        if params.shadows != 0 { p.sha = params.shadows }
        if params.whites != 0 { p.whi = params.whites }
        if params.blacks != 0 { p.bla = params.blacks }

        // Color
        if params.temperature != 0 { p.tem = params.temperature }
        if params.tint != 0 { p.tin = params.tint }
        if params.saturation != 0 { p.sat = params.saturation }
        if params.vibrance != 0 { p.vib = params.vibrance }

        // Skin tone
        if params.skinToneHue != 0 { p.skH = params.skinToneHue }
        if params.skinToneSaturation != 0 { p.skS = params.skinToneSaturation }

        // HSL - encode as array of arrays if any channel is non-identity
        if params.hsl != .identity {
            var hslData: [[Float]] = []
            for i in 0..<8 {
                let channel = params.hsl[i]
                if channel.hue != 0 || channel.saturation != 0 || channel.luminance != 0 {
                    hslData.append([Float(i), channel.hue, channel.saturation, channel.luminance])
                }
            }
            if !hslData.isEmpty {
                p.hsl = hslData
            }
        }

        // Split tone
        if params.splitTone != .identity {
            if params.splitTone.highlightHue != 0 { p.stHH = params.splitTone.highlightHue }
            if params.splitTone.highlightSaturation != 0 { p.stHS = params.splitTone.highlightSaturation }
            if params.splitTone.shadowHue != 0 { p.stSH = params.splitTone.shadowHue }
            if params.splitTone.shadowSaturation != 0 { p.stSS = params.splitTone.shadowSaturation }
            if params.splitTone.balance != 0 { p.stB = params.splitTone.balance }
        }

        // Tone curve - encode if non-identity
        if params.toneCurve != .identity {
            var curves: [[[Float]]] = []
            let allCurves = [params.toneCurve.composite, params.toneCurve.red, params.toneCurve.green, params.toneCurve.blue]
            for curve in allCurves {
                let points = curve.map { [$0.x, $0.y] }
                curves.append(points)
            }
            p.tc = curves
        }

        // Effects
        if params.clarity != 0 { p.cla = params.clarity }
        if params.fade != 0 { p.fad = params.fade }
        if params.sharpness != 0 { p.shp = params.sharpness }
        if params.sharpenRadius != 1.0 { p.shR = params.sharpenRadius }
        if params.noiseReduction != 0 { p.noR = params.noiseReduction }

        // Grain
        if params.grain.amount > 0 {
            p.grA = params.grain.amount
            p.grS = params.grain.size
            p.grR = params.grain.roughness
            p.grM = params.grain.monochromatic
        }

        // Vignette
        if params.vignette.amount != 0 {
            p.viA = params.vignette.amount
            p.viM = params.vignette.midpoint
            p.viR = params.vignette.roundness
            p.viF = params.vignette.feather
        }

        // Bloom
        if params.bloom.intensity > 0 {
            p.blI = params.bloom.intensity
            p.blR = params.bloom.radius
            p.blT = params.bloom.threshold
        }

        // Halation
        if params.halation.intensity > 0 {
            p.haI = params.halation.intensity
            p.haH = params.halation.hue
            p.haS = params.halation.spread
        }

        // Fuji simulation params
        if params.filmSimulation != .none {
            p.fsT = params.filmSimulation.rawValue
        }
        if params.dynamicRange != .dr100 {
            p.drM = params.dynamicRange.rawValue
        }
        if params.colorChrome.effect != .off {
            p.ccE = params.colorChrome.effect.rawValue
        }
        if params.colorChrome.fxBlue != .off {
            p.ccB = params.colorChrome.fxBlue.rawValue
        }
        if params.whiteBalanceShift.redShift != 0 {
            p.wbR = params.whiteBalanceShift.redShift
        }
        if params.whiteBalanceShift.blueShift != 0 {
            p.wbB = params.whiteBalanceShift.blueShift
        }

        self.p = p
    }

    // swiftlint:disable:next cyclomatic_complexity
    func toFilterPreset() -> FilterPreset {
        var params = FilterParameters.identity

        // Light
        if let v = p.exp { params.exposure = v }
        if let v = p.con { params.contrast = v }
        if let v = p.hig { params.highlights = v }
        if let v = p.sha { params.shadows = v }
        if let v = p.whi { params.whites = v }
        if let v = p.bla { params.blacks = v }

        // Color
        if let v = p.tem { params.temperature = v }
        if let v = p.tin { params.tint = v }
        if let v = p.sat { params.saturation = v }
        if let v = p.vib { params.vibrance = v }

        // Skin tone
        if let v = p.skH { params.skinToneHue = v }
        if let v = p.skS { params.skinToneSaturation = v }

        // HSL
        if let hslData = p.hsl {
            for channelData in hslData where channelData.count >= 4 {
                let idx = Int(channelData[0])
                if idx >= 0 && idx < 8 {
                    params.hsl[idx] = HSLAdjustments.HSLChannel(
                        hue: channelData[1],
                        saturation: channelData[2],
                        luminance: channelData[3]
                    )
                }
            }
        }

        // Split tone
        if let v = p.stHH { params.splitTone.highlightHue = v }
        if let v = p.stHS { params.splitTone.highlightSaturation = v }
        if let v = p.stSH { params.splitTone.shadowHue = v }
        if let v = p.stSS { params.splitTone.shadowSaturation = v }
        if let v = p.stB { params.splitTone.balance = v }

        // Tone curve
        if let tc = p.tc, tc.count == 4 {
            for (index, curvePoints) in tc.enumerated() {
                let points = curvePoints.compactMap { point -> ToneCurveData.CurvePoint? in
                    guard point.count >= 2 else { return nil }
                    return ToneCurveData.CurvePoint(x: point[0], y: point[1])
                }
                if !points.isEmpty {
                    switch index {
                    case 0: params.toneCurve.composite = points
                    case 1: params.toneCurve.red = points
                    case 2: params.toneCurve.green = points
                    case 3: params.toneCurve.blue = points
                    default: break
                    }
                }
            }
        }

        // Effects
        if let v = p.cla { params.clarity = v }
        if let v = p.fad { params.fade = v }
        if let v = p.shp { params.sharpness = v }
        if let v = p.shR { params.sharpenRadius = v }
        if let v = p.noR { params.noiseReduction = v }

        // Grain
        if let a = p.grA {
            params.grain.amount = a
            params.grain.size = p.grS ?? 0.5
            params.grain.roughness = p.grR ?? 0.5
            params.grain.monochromatic = p.grM ?? true
        }

        // Vignette
        if let a = p.viA {
            params.vignette.amount = a
            params.vignette.midpoint = p.viM ?? 0.5
            params.vignette.roundness = p.viR ?? 0
            params.vignette.feather = p.viF ?? 0.5
        }

        // Bloom
        if let i = p.blI {
            params.bloom.intensity = i
            params.bloom.radius = p.blR ?? 0.5
            params.bloom.threshold = p.blT ?? 0.8
        }

        // Halation
        if let i = p.haI {
            params.halation.intensity = i
            params.halation.hue = p.haH ?? 0
            params.halation.spread = p.haS ?? 0.5
        }

        // Fuji simulation
        if let fsT = p.fsT, let simType = FilmSimulationType(rawValue: fsT) {
            params.filmSimulation = simType
        }
        if let drM = p.drM, let drMode = DynamicRangeMode(rawValue: drM) {
            params.dynamicRange = drMode
        }
        if let ccE = p.ccE, let effect = ColorChromeData.ColorChromeLevel(rawValue: ccE) {
            params.colorChrome.effect = effect
        }
        if let ccB = p.ccB, let fxBlue = ColorChromeData.ColorChromeLevel(rawValue: ccB) {
            params.colorChrome.fxBlue = fxBlue
        }
        if let wbR = p.wbR {
            params.whiteBalanceShift.redShift = wbR
        }
        if let wbB = p.wbB {
            params.whiteBalanceShift.blueShift = wbB
        }

        return FilterPreset(
            name: n,
            category: .custom,
            source: .imported(sourceName: "QR Code"),
            parameters: params
        )
    }
}

// MARK: - Recipe Scanner View (Import)

@available(iOS 17.0, *)
struct RecipeScannerView: View {
    @Environment(\.dismiss) private var dismiss

    let existingNames: Set<String>
    let onImport: (FilterPreset) -> Void

    @State private var scannedCode: String?
    @State private var importedRecipe: FilterPreset?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cameraPermissionDenied = false
    @State private var isCheckingPermission = true
    @State private var cameraPermissionGranted = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingImage = false

    init(existingNames: Set<String> = [], onImport: @escaping (FilterPreset) -> Void) {
        self.existingNames = existingNames
        self.onImport = onImport
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isCheckingPermission {
                    // Loading state while checking permission
                    ProgressView()
                        .tint(.white)
                } else if cameraPermissionDenied {
                    permissionDeniedView
                } else if let recipe = importedRecipe {
                    importSuccessView(recipe)
                } else if cameraPermissionGranted {
                    QRScannerRepresentable(scannedCode: $scannedCode)
                        .ignoresSafeArea()
                        .overlay(scannerOverlay)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ import recipe")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .alert("Invalid QR Code", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    scannedCode = nil
                }
            } message: {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await checkCameraPermission()
        }
        .onChange(of: scannedCode) { _, newValue in
            if let code = newValue {
                processScannedCode(code)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem {
                Task {
                    await processSelectedPhoto(newItem)
                }
            }
        }
    }

    // MARK: - Scanner Overlay

    private var scannerOverlay: some View {
        VStack {
            Spacer()

            // Scanning frame
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )

                if isProcessingImage {
                    ProgressView()
                        .tint(.yellow)
                        .scaleEffect(1.5)
                }
            }

            Spacer()

            // Instructions and gallery button
            VStack(spacing: 16) {
                Text("point camera at recipe qr code")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))

                Text("or")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("choose from gallery")
                    }
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(Color.yellow, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 50)
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("camera access required")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            Text("enable camera access in settings\nto scan recipe qr codes")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("open settings")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
            }
            .buttonStyle(.plain)

            // Divider
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            // Gallery option
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                    Text("choose from gallery")
                }
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.yellow)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Color.yellow, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .overlay {
            if isProcessingImage {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .tint(.yellow)
                            .scaleEffect(1.5)
                    )
            }
        }
    }

    // MARK: - Import Success View

    private func importSuccessView(_ recipe: FilterPreset) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("recipe found!")
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Text(recipe.name)
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.yellow)

            Button {
                onImport(recipe)
                dismiss()
            } label: {
                Text("import recipe")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }

    // MARK: - Camera Permission

    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await MainActor.run {
                cameraPermissionGranted = true
                isCheckingPermission = false
            }
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                if granted {
                    cameraPermissionGranted = true
                } else {
                    cameraPermissionDenied = true
                }
                isCheckingPermission = false
            }
        case .denied, .restricted:
            await MainActor.run {
                cameraPermissionDenied = true
                isCheckingPermission = false
            }
        @unknown default:
            await MainActor.run {
                isCheckingPermission = false
            }
        }
    }

    // MARK: - Process Scanned Code

    private func processScannedCode(_ code: String) {
        guard let data = code.data(using: .utf8) else {
            errorMessage = "Could not read QR code data"
            showError = true
            return
        }

        do {
            let recipeData = try JSONDecoder().decode(RecipeQRData.self, from: data)
            var preset = recipeData.toFilterPreset()

            // Check for duplicate name and add date suffix if needed
            if existingNames.contains(preset.name) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yy"
                let dateString = dateFormatter.string(from: Date())
                preset = FilterPreset(
                    id: preset.id,
                    name: "\(preset.name) \(dateString)",
                    category: preset.category,
                    source: preset.source,
                    parameters: preset.parameters,
                    metadata: preset.metadata
                )
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            importedRecipe = preset
        } catch {
            errorMessage = "This QR code is not a valid Loopix recipe"
            showError = true
        }
    }

    // MARK: - Process Selected Photo

    private func processSelectedPhoto(_ item: PhotosPickerItem) async {
        isProcessingImage = true
        defer {
            Task { @MainActor in
                isProcessingImage = false
                selectedPhotoItem = nil
            }
        }

        // Load image data
        guard let data = try? await item.loadTransferable(type: Data.self),
              let ciImage = CIImage(data: data) else {
            await MainActor.run {
                errorMessage = "Could not load image"
                showError = true
            }
            return
        }

        // Detect QR code in image
        let context = CIContext()
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        guard let features = detector?.features(in: ciImage),
              let qrFeature = features.first as? CIQRCodeFeature,
              let messageString = qrFeature.messageString else {
            await MainActor.run {
                errorMessage = "No QR code found in image"
                showError = true
            }
            return
        }

        // Process the detected QR code
        await MainActor.run {
            processScannedCode(messageString)
        }
    }
}

// MARK: - QR Scanner UIKit Representable

@MainActor
struct QRScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    @MainActor
    class Coordinator: NSObject, QRScannerDelegate {
        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func didScanCode(_ code: String) {
            scannedCode = code
        }
    }
}

// MARK: - QR Scanner View Controller

@MainActor
protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

@MainActor
class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private var metadataDelegate: MetadataOutputDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            // Create delegate that handles callback on main queue
            let outputDelegate = MetadataOutputDelegate { [weak self] code in
                Task { @MainActor in
                    self?.handleScannedCode(code)
                }
            }
            metadataDelegate = outputDelegate
            metadataOutput.setMetadataObjectsDelegate(outputDelegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        captureSession = session

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func startScanning() {
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    private func handleScannedCode(_ code: String) {
        guard !hasScanned else { return }
        hasScanned = true
        stopScanning()
        delegate?.didScanCode(code)
    }
}

// MARK: - Metadata Output Delegate (non-isolated for AVFoundation callback)

private final class MetadataOutputDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let onCodeScanned: @Sendable (String) -> Void

    init(onCodeScanned: @escaping @Sendable (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        super.init()
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        onCodeScanned(stringValue)
    }
}
