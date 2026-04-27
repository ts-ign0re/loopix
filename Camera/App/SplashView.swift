import SwiftUI

struct SplashView: View {

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color("BrandYellow")
                .ignoresSafeArea()

            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1)) {
                rotation = 360
            }
        }
    }
}
