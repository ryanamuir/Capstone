import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    //FirebaseApp.configure()
    return true
  }
}

@main
struct GainsAndGrainsApp: App {
    @StateObject private var manager : HealthManager
    @StateObject private var authState : AuthState
    //@StateObject private var mealtracker : MealTracker
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
                FirebaseApp.configure()
                // Make exactly one AuthState instance…
                let auth = AuthState()

                // …use it for the @StateObject…
                _authState = StateObject(wrappedValue: auth)

                // …and hand that same instance to your HealthManager.
                _manager = StateObject(wrappedValue: HealthManager(authState:auth))
                
                //_mealtracker = StateObject(wrappedValue: MealTracker(authState:auth))
            }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(manager)
                .accentColor(Color("AccentColor"))
                //.environmentObject(mealtracker)
        }
    }
}
