import SwiftUI

struct LastPhotoThumbnail: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: CameraTheme.thumbnailSize, height: CameraTheme.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(CameraTheme.surface)
                    .frame(width: CameraTheme.thumbnailSize, height: CameraTheme.thumbnailSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}
