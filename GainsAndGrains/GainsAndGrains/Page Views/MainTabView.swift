
//
//  Dashboard2 .swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 10/05/2025.
//
import SwiftUI
import CoreML


class TabSelectionManager: ObservableObject {
    @Published var currentTab: Int = 0
    @Published var tappedTab: Int = 0 // changes even when re-tapping same tab
}




struct HomeView: View {
    @EnvironmentObject private var manager: HealthManager
    @StateObject private var tabManager = TabSelectionManager()

    var body: some View {
        TabView(selection: $tabManager.currentTab) {
            
            NavigationStack {
                HealthPage()
                    .navigationTitle("Summary")
                    .environmentObject(tabManager)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                SearchWorkouts()
                    .navigationTitle("Find Detailed Info")
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            NavigationStack {
                Youtube()
                    .navigationTitle("Workout")
            }
            .tabItem {
                Label("Exercise", systemImage: "dumbbell.fill")
            }
            .tag(2)

            NavigationStack {
                MealTrackingView()
                    .navigationTitle("Meal")
            }
            .tabItem {
                Label("Nutrition", systemImage: "fork.knife")
            }
            .tag(3)

            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "gear")
            }
            .tag(4)
        }
        .onAppear {
            // Optional: log initial tab
            tabManager.tappedTab = tabManager.currentTab
        }
        .onChange(of: tabManager.currentTab) { newValue in
            tabManager.tappedTab = newValue
        }
    }
}





struct HomeView_preview: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
