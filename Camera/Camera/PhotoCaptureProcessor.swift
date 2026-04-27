import AVFoundation
import CoreImage
import Photos
import UIKit

/// Handles processed photo capture — applies filter + grain on ISP-rendered image, saves HEIC
final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {

    private let filter: CameraFilter
    private let filterIntensity: Float
    private let grainData: GrainData
    private let grainSeed: Float
    private let completion: @Sendable (Data?) -> Void
    private let ciContext = CIContext(options: [.cacheIntermediates: false])

    init(
        filter: CameraFilter,
        filterIntensity: Float = 1.0,
        grainData: GrainData,
        grainSeed: Float,
        completion: @escaping @Sendable (Data?) -> Void
    ) {
        self.filter = filter
        self.filterIntensity = filterIntensity
        self.grainData = grainData
        self.grainSeed = grainSeed
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("PhotoCapture error: \(error!.localizedDescription)")
            completion(nil)
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: data) else {
            completion(nil)
            return
        }

        let processed = applyFilterAndGrain(to: ciImage)
        saveToPhotoLibrary(processed)
    }

    private func applyFilterAndGrain(to image: CIImage) -> CIImage {
        var result = LiveFilterPipeline.apply(filter, to: image, intensity: filterIntensity)
        let profiledGrain = filter.profiledGrainData(from: grainData)

        if profiledGrain.isActive {
            if let grained = try? MetalFilterLoader.shared.applyGrain(
                to: result,
                grainData: profiledGrain,
                time: grainSeed,
                clumpStrength: filter.grainClumpBoost
            ) {
                result = grained
            }
        }

        return result
    }

    private func saveToPhotoLibrary(_ image: CIImage) {
        let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)!

        guard let heicData = try? ciContext.heifRepresentation(
            of: image,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
        ) else { return }

        // Thumbnail for UI
        let thumbnail = generateThumbnail(from: image)
        completion(thumbnail)

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: heicData, options: nil)
        }
    }

    private func generateThumbnail(from image: CIImage) -> Data? {
        let extent = image.extent
        let scale = 120.0 / max(extent.width, extent.height)
        let thumb = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = ciContext.createCGImage(thumb, from: thumb.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7)
    }
}
