import SwiftUI

struct ContentView: View {
    
    @State private var showMainView: Bool = false
    
    var body: some View {
        if showMainView {
            MainTabView()
        }
        else {
            SplashScreenView()
                .onAppear(
                    perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showMainView = true
                            }
                        }
                        
                    }
                )
        }
    }
}

#Preview {
    ContentView()
}
