import SwiftUI
import Foundation

struct MainTabView: View {

    var body: some View {

        TabView {

            

            Tab("Camera", systemImage: "camera.fill") {

                CameraView()

            }

            

            Tab("Saved", systemImage: "folder.fill") {

                SavedView()

            }

            

            Tab("Questions", systemImage: "questionmark.bubble.fill") {

                ChatView()

            }

            

            Tab("Facts", systemImage: "lightbulb.fill") {

                FactsView() 

            }

        }

        .tabViewStyle(.sidebarAdaptable)

        .tint(.blue)

    }

}
