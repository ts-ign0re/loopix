//
//  SplashView.swift
//  FilmBox
//
//  Animated splash screen with rotating Loopix logo
//

import SwiftUI

struct SplashView: View {

    // MARK: - State

    @State private var rotation: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Yellow background matching the icon
            Color(red: 0.96, green: 0.84, blue: 0.28)
                .ignoresSafeArea()

            // Rotating logo
            if let uiImage = UIImage(named: "Icon") ?? loadIconFromBundle() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(rotation))
            }
        }
        .onAppear {
            // Rotate 360° clockwise over 2 seconds
            withAnimation(.linear(duration: 2)) {
                rotation = 360
            }
        }
    }

    // MARK: - Helpers

    /// Load icon from bundle if not in asset catalog
    private func loadIconFromBundle() -> UIImage? {
        guard let path = Bundle.main.path(forResource: "Icon", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path) else {
            return nil
        }
        return image
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
