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
            // Yellow background (same as launch screen)
            Color("BrandYellow")
                .ignoresSafeArea()

            // Rotating logo (transparent PNG)
            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            // Rotate 360° clockwise over 2 seconds
            withAnimation(.linear(duration: 2)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
