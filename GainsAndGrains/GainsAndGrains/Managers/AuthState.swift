import SwiftUI
import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

enum AuthenticationState {
case unauthenticated
case authenticating
case authenticated
case onboarding
}

enum AuthenticationFlow{
    case login
    case home
}

@MainActor
class AuthState: ObservableObject {
    @Published var fullname : String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmedpassword:String=""
    @Published var errormessage:String = ""
    @Published var flow: AuthenticationFlow = .login
    @Published var isValid: Bool = false
    @Published var auth_state: AuthenticationState = .unauthenticated
    @Published var user: FirebaseAuth.User?
    @Published var currentuser: User?
    @Published var workouts : [WorkoutItem]?
    //@Published var shouldRefreshWorkouts: Bool = false
    @Published var meals: [Date: [Meal]]?
    @Published var foodsuggestions: [Food] = []
    @Published var workout_description: [WorkoutDescription] = []
    //@Published var foods: [Food]?
    
    init(){
        registerAuthStateHandler()
        $flow
            .combineLatest($email,$password,$confirmedpassword)
            .map{flow,email,password,confirmedpassword in
                flow == .login
                ? !(email.isEmpty || password.isEmpty)
                : !(email.isEmpty || password.isEmpty || confirmedpassword.isEmpty)
            }
            .assign(to: &$isValid)
        
    }
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    func registerAuthStateHandler() {
        if authStateHandle == nil {
            authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                
                // CHECKS IF A FIREBASE USER IS LOGGED IN
                if user == nil {
                    self.auth_state = .unauthenticated
                    self.currentuser = nil
                    print("🚪 Signed out: unauthenticated.")
                }
                // IF A USER IS LOGGED IN IT FETCHES THAT USER INFORMATION AND WORKOUTS
                else {
                    print("👤 Authenticated Firebase user found. UID: \(user!.uid)")
                    Task {
                        
                        //Assigns the relevant information from the databases and changes the authState
                        await self.fetchUser()
                        await self.fetchWorkouts()
                        
                        
                    }
                }
            }
        }
    }
}


extension AuthState{
    
    
    func signInWithEmailandPassword()async -> Bool{
        auth_state = .authenticating
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
            print("User \(result.user.uid) signed in")
            await fetchUser()
            await fetchAllMeals()
            return true
        }
        catch{
            print(error)
            errormessage = error.localizedDescription
            return false
        }
        
    }
    
    func signUpwithEmailandPassword()async -> Bool{
        auth_state = .authenticating
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
            auth_state = .onboarding
            
            print("User \(result.user.uid) signed in")
            return true
        }
        catch{
            print(error)
            errormessage = error.localizedDescription
            return false
        }
        
    }
    
    func signOut()async -> Bool{
        do{
            // SETS THE EMAIL BACK ON THE LOG IN SCREEN TO BE THE LAST USED EMAIL TO SIGN IN
            // HOWEVER IT REMOVES THE PASSWORD
            self.email = Auth.auth().currentUser?.email ?? ""
            self.password = ""
            
            
            try Auth.auth().signOut()
            return true
        }
        catch{
            print(error)
            return false
        }
    }
    
    func deleteAccount() async -> Bool{
        do{
            try await Firestore.firestore()
                .collection("UserInputs")
                .document(Auth.auth().currentUser?.uid ?? UUID().uuidString)
                .delete()
            try await user?.delete()
            email=""
            password=""
            confirmedpassword=""
            currentuser = nil
            
            return true
            
        }
        catch{
            print(error)
            return false
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No current user UID")
            return
        }
        
        print("🔍 Fetching user with UID: \(uid)")
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("UserInputs")
                .document(uid)
                .getDocument()
            
            if snapshot.exists {
                self.currentuser = try snapshot.data(as: User.self)
                print("✅ User loaded: \(self.currentuser?.fullname ?? "Unknown")")
                self.auth_state = .authenticated
            } else {
                print("⚠️ No user document found — switching to onboarding.")
                self.auth_state = .onboarding
            }
        } catch {
            print("❌ Firestore fetch error: \(error.localizedDescription)")
            self.auth_state = .unauthenticated
        }
    }
    
    //fetching user documents
    func fetchWorkouts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No current user UID")
            return
        }
        print("🔍 Fetching user with UID: \(uid)")
        
        do {
            let workouts = try await Firestore.firestore().collection("UserInputs").document(uid).collection("workouts").getDocuments()
            
            if !workouts.isEmpty{
                let decodedWorkouts = try workouts.documents.compactMap {
                    try $0.data(as: WorkoutItem.self)
                }
                self.workouts = decodedWorkouts
                
                print("✅ Loaded \(decodedWorkouts.count) workouts")
            } else {
                
                print("⚠️ No workout document found")
                
            }
            
        }
        catch {
            print("❌ Firestore fetch error: \(error.localizedDescription)")
        }
        
        
        
    }
    
    func StoreWorkouts(workout:WorkoutItem)async {
       do {
           
           let encodedUser = try Firestore.Encoder().encode(workout)
           
           
           try await Firestore.firestore()
               .collection("UserInputs")
               .document(Auth.auth().currentUser?.uid ?? UUID().uuidString)
               .collection("workouts")
               .document(workout.id)
               .setData(encodedUser)
           print("✅ Workout stored ")
           //print("🚀 Storing workout to Firebase: \(workout.title), duration: \(workout.duration)")

           //await self.fetchWorkouts()
           
       } catch {
           print("🔥 Firestore save failed: \(error.localizedDescription)")
           self.errormessage = "Failed to save user data."
       }
   }
    
    func fetchFoodSuggestions(matching query: String) async {
        guard !query.isEmpty else {
            self.foodsuggestions = []
          return
        }
        
        do {
          let db = Firestore.firestore()
          let end = query + "\u{f8ff}"
          let snap = try await db.collection("foods")
            .order(by: "name")
            .start(at: [query])
            .end(at: [end])
            .getDocuments()
            
            if !snap.isEmpty{
                let items = try snap.documents.compactMap { try $0.data(as: Food.self) }
                self.foodsuggestions = items
                print("\(self.foodsuggestions)")
            }
            else{
                print("NO MATCH WAS FOUND")
            }
          
        } catch {
          print("❌ failed to fetch food suggestions:", error)
          self.foodsuggestions = []
        }
      }
    

    
    func fetchExerciseInfo(matching query: String) async {
        guard !query.isEmpty else {
            self.workout_description = []
          return
        }
        
        do {
          let db = Firestore.firestore()
          let end = query + "\u{f8ff}"
          let snap = try await db.collection("workout_info")
            .order(by: "Title")
            .start(at: [query])
            .end(at: [end])
            .getDocuments()
            
            if !snap.isEmpty{
                let items = try snap.documents.compactMap { try $0.data(as: WorkoutDescription.self) }
                self.workout_description = items
                print("\(self.workout_description.count)")
            }
            else{
                print("NO MATCH WAS FOUND")
            }
          
        } catch {
          print("❌ failed to fetch food suggestions:", error)
          self.workout_description = []
        }
      }
    
    func storeAllWorkouts(workouts: [WorkoutItem]) async {
        for workout in workouts {
            await StoreWorkouts(workout: workout)
        }
    }
    
    func deleteWorkout(workout: WorkoutItem) async {
        do{
            try await Firestore.firestore()
                .collection("UserInputs")
                .document(Auth.auth().currentUser?.uid ?? UUID().uuidString)
                .collection("workouts")
                .document(workout.id)
                .delete()
        }
        catch{
            print(" ❌ Workout was not sucessfully deleted")
        }
        
    }
    
    func StoreUser(user:User) async {
                do {
                    let encodedUser = try Firestore.Encoder().encode(user)
                    
                    try await Firestore.firestore()
                        .collection("UserInputs")
                        .document(user.id)
                        .setData(encodedUser)
                    
                    await signInWithEmailandPassword()
                    
                } catch {
                    print("🔥 Firestore save failed: \(error.localizedDescription)")
                    errormessage = "Failed to save user data."
                }
            
    }
    
    func updateUser(user:User, field:String, value:Any) async {
        do {
            
            try await Firestore.firestore()
                .collection("UserInputs")
                .document(user.id)
                .setData([field:value],merge: true)
        }
        catch{
            print("🔥 Firestore save failed: \(error.localizedDescription)")
        }
    }
    
    func addMeal(_ meal:Meal) async{
        
        guard let uid = Auth.auth().currentUser?.uid else { print("No user found"); return}
        do{
            let encodedmeal = try Firestore.Encoder().encode(meal)
            try await Firestore.firestore()
                .collection("UserInputs")
                .document(uid)
                .collection("meals")
                .document(meal.id)
                .setData(encodedmeal)
            print("✅ Meal stored ")
        }
        catch{
            print("Error occucred: \(error.localizedDescription)")
        }
    }
    
      func fetchAllMeals() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
          let snap = try await Firestore.firestore()
            .collection("UserInputs")
            .document(uid)
            .collection("meals")
            .getDocuments()
          let docs = snap.documents.compactMap { try? $0.data(as: Meal.self) }
          // Group by start-of-day
            self.meals = Dictionary(grouping: docs) {
            Calendar.current.startOfDay(for: $0.date)
          }
          DispatchQueue.main.async {
            // If you want to push it into your MealTracker…
             //self.mealTracker.meals = grouped
          }
        } catch {
          print("⚠️ failed to fetch meals:", error)
        }
      }
    
    

    
    func convertAlltolowercase() async{
        
        do{
          
            let exercises = try await Firestore.firestore().collection("workout_info").getDocuments()
            
            if !exercises.isEmpty{
                
                let decodedFoodsDict = try exercises.documents.reduce(into: [String: WorkoutDescription]()) { dict, doc in
                    let food = try doc.data(as: WorkoutDescription.self)
                    dict[doc.documentID] = food
                }
                
                for (id, var food) in decodedFoodsDict {
                    food.Title = food.Title.lowercased()
                    
                     Firestore.firestore()
                        .collection("workout_info")
                        .document(id)
                        .setData(from:food,merge: true)
                    
                    
                }
                
                print("✅ Loaded \(decodedFoodsDict.count) workouts")
            } else {
                
                print("⚠️ No workout document found")
                
            }
        }
        catch{
            print("SMTH WENT WRONG")
        }
    }
    
    
    /*func deleteDuplicates() async {
        do {
            let foods = try await Firestore.firestore().collection("workout_info").getDocuments()
            var uniqueFoods: [String] = []
            var duplicatesToDelete: Set<String> = []

            for entry in foods.documents {
                if let food = try? entry.data(as: WorkoutDescription.self) {
                    if uniqueFoods.contains(food.Title) {
                        duplicatesToDelete.insert(entry.documentID)
                    } else {
                        uniqueFoods.append(food.Title)
                    }
                }
            }

            for id in duplicatesToDelete {
                try await Firestore.firestore()
                    .collection("workout_info")
                    .document(id)
                    .delete()
            }

            print("Number of rows deleted was \(duplicatesToDelete.count)")
        } catch {
            print("Error deleting duplicates: \(error)")
        }
    } */



}




