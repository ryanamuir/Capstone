
//
//  Dashboard2 .swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 10/05/2025.
//
import SwiftUI
import CoreML



struct HomeView: View {
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "gear")
                }
        }
    }
}

struct HomeView_preview: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
