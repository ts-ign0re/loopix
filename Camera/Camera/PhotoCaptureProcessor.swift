import AVFoundation
import CoreImage
import Photos
import UIKit

enum PhotoCaptureError: Error {
    case invalidImageData
    case encodingFailed
    case saveFailed
}

/// Handles processed photo capture — applies filter + grain on ISP-rendered image, saves HEIC
final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {

    private let filter: CameraFilter
    private let filterIntensity: Float
    private let grainData: GrainData
    private let grainSeed: Float
    private let completion: @Sendable (Data?, Error?) -> Void
    private let ciContext = CIContext(options: [.cacheIntermediates: false])

    init(
        filter: CameraFilter,
        filterIntensity: Float = 1.0,
        grainData: GrainData,
        grainSeed: Float,
        completion: @escaping @Sendable (Data?, Error?) -> Void
    ) {
        self.filter = filter
        self.filterIntensity = filterIntensity
        self.grainData = grainData
        self.grainSeed = grainSeed
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("PhotoCapture error: \(error.localizedDescription)")
            completion(nil, error)
            return
        }

        // `applyOrientationProperty` bakes the capture orientation (carried in the photo's
        // EXIF metadata) into the pixels, so the re-encoded HEIC is upright regardless of
        // how the Photos app interprets orientation tags.
        guard let data = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            completion(nil, PhotoCaptureError.invalidImageData)
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
        ) else {
            completion(nil, PhotoCaptureError.encodingFailed)
            return
        }

        let thumbnail = generateThumbnail(from: image)

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: heicData, options: nil)
        } completionHandler: { [completion] success, error in
            // Only report success once the photo is actually in the library.
            if success {
                completion(thumbnail, nil)
            } else {
                completion(nil, error ?? PhotoCaptureError.saveFailed)
            }
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
