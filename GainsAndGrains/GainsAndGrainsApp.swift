import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct GainsAndGrainsApp: App {
    @StateObject private var authState = AuthState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
        }
    }
}
