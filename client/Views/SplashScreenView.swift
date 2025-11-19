import SwiftUI

struct SplashScreenView: View {
    @State private var showPlate = false
    @State private var rotatePlate = false
    @State private var showFork = false
    @State private var showKnife = false
    @State private var showTitle = false
    @State private var fadeOut = false

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                LinearGradient(
                    gradient: .init(colors: [.blue, .cyan]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(.white)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .scaleEffect(showPlate ? 1 : 0.1)
                    .rotationEffect(.degrees(rotatePlate ? 360 : 0))
                    .opacity(fadeOut ? 0 : 1)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.02, height: size * 0.22)
                    .offset(x: showFork ? -size * 0.25 : -size * 0.6,
                            y: -size * 0.1)
                    .rotationEffect(.degrees(-45))
                    .opacity(fadeOut ? 0 : 1)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.02, height: size * 0.22)
                    .offset(x: showKnife ? size * 0.25 : size * 0.6,
                            y: -size * 0.1)
                    .rotationEffect(.degrees(45))
                    .opacity(fadeOut ? 0 : 1)

                Circle()
                    .stroke(lineWidth: 4)
                    .frame(width: size * (showPlate ? 0.45 : 0.35),
                           height: size * (showPlate ? 0.45 : 0.35))
                    .foregroundColor(.white.opacity(0.3))
                    .opacity(showPlate ? 0 : 0.8)

                Text("FoodLens")
                    .font(.system(size: size * 0.13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: size * 0.3)
            }
            .opacity(fadeOut ? 0 : 1)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showPlate = true
            }

            withAnimation(.easeInOut(duration: 1.5).delay(0.4)) {
                rotatePlate = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                showFork = true
                showKnife = true
            }

            withAnimation(.easeIn(duration: 0.5).delay(1.2)) {
                showTitle = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    fadeOut = true
                }
            }
        }
    }
}
