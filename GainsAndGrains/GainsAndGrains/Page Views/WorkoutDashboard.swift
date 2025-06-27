import SwiftUI
import UIKit
import CoreML
import FirebaseFirestore


struct Youtube: View {
    let categories = ["All"] + Preprocessor.shared.bodyPartCats
    
    @EnvironmentObject private var manager: HealthManager
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var tabManager: TabSelectionManager
    @State var level: String = "Intermediate"
    @State var rating: Double = 8
    @State var model = try! Workouts(configuration: MLModelConfiguration())
    @State var pre = Preprocessor.shared
    @State var bodyParts = Array(Preprocessor.shared.bodyPartCats.shuffled().prefix(5))
    @State private var recommendations: [String: [String]] = [:]
    @State private var popularItems: [WorkoutItem] = [WorkoutItem.MOCK_WORKOUT.cloneWithNewID()]
    @State var filteredworkouts: [WorkoutItem] = []
    @State var searchword = ""
    @State private var didInitialFetch = false
    @State private var categoryFilter: String? = "All"
    
    func filterPopularItems() {
        withAnimation(.easeInOut) {
            if let category = categoryFilter {
                if category == "All" {
                    popularItems = filteredworkouts
                } else {
                    popularItems = filteredworkouts.filter { $0.category == category }
                }
            }
        }
    }
    
    func searchFilter(){
        withAnimation(.easeInOut){
            if !searchword.isEmpty {
                popularItems = filteredworkouts.filter { $0.title.localizedCaseInsensitiveContains(searchword) || $0.description.contains(where: { workout in workout.name.localizedCaseInsensitiveContains(searchword)}) || $0.category.localizedCaseInsensitiveContains(searchword)}
            } else {
                popularItems = filteredworkouts
            }
        }
    }
    
    private func computeRecommendations(for user: User) {
        var newRecs: [String: [String]] = [:]
        var exercise_type:String = ""
        var equip_access: String = ""
        for part in bodyParts {
            do {
                //MATCHES USER INPUT TO DATA USED TO TRAIN ML ALGO
                switch user.fitnessGoal{
                case "Build muscle": exercise_type = "Strength"
                case "Lose weight": exercise_type = "Cardio"
                case "General fitness": exercise_type = "Plyometrics"
                case "Improve endurance": exercise_type = "Cardio"
                default: exercise_type = "Strength"
                }
                
                //MATCHES USER INPUT TO DATA USED TO TRAIN ML ALGO
                switch user.equipmentAccess{
                case "None" : equip_access = "None"
                case "Weights" : equip_access = ["Barbell","Dumbbell","E-Z Curl Bar","Exercise Ball","Foam Roll","Kettlebells","Medicine Ball",].randomElement() ?? "Barbell"
                    
                case "Machines" : equip_access = "Cable"
                case "Weights and Machines": equip_access = ["Barbell","Dumbbell","E-Z Curl Bar","Exercise Ball","Foam Roll","Kettlebells","Medicine Ball","Machine"].randomElement() ?? "Machine"
                default: equip_access = "Dumbbell"
                
                }
                
                let mlArr = try pre.makeInputArray(
                    type: exercise_type,
                    bodyPart: part,
                    equipment: equip_access,
                    level: level,
                    rating: rating
                )
                let input = WorkoutsInput(dense_input: mlArr)
                let output = try model.prediction(input: input)
                let probs = output.Identity
                let top2 = probs.topKIndices(3)
                let suggestions = top2.map { pre.titles[$0] }
                newRecs[part] = suggestions
            } catch {
                newRecs[part] = ["—", "—", "—"]
            }
        }
        recommendations = newRecs
    }

    var body: some View {
            Group {
                if let user = authState.currentuser {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            RecommendationSection(popularItems:$popularItems, bodyParts: bodyParts, recommendations: recommendations)
                            CategorySection_(selectedCategory:$categoryFilter)
                            PopularSection(popularItems: $popularItems)
                        }
                        .padding(.top, 8)
                    }
                    .searchable(text: $searchword)
                    .onChange(of: searchword, searchFilter)
                    .onChange(of: categoryFilter, filterPopularItems)
                    .task {
                         // only fetch new when the application is closed
                        // this will still select changes made within the system without fetching 
                          await authState.fetchWorkouts()
                          if let stored = authState.workouts {
                            filteredworkouts = stored       // your “all” array
                            popularItems    = stored       // your “displayed” array
                            computeRecommendations(for: user)
                          }
                      }
                } else {
                    ProgressView("Loading your dashboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
}


//aims to create a routine given the category and exercise descriptons with default sets
func makenewRoutine(category:String, exercise_titles:[String]) -> WorkoutItem {
    
    var exercises : [Workout] = []
    
    for titles in exercise_titles {
        exercises.append(Workout.MOCK_WORKOUT.cloneWithnewName(title: titles))
    }
    return WorkoutItem.MOCK_WORKOUT.createnewWorkout(name:category, workout: exercises)
    
}


struct RecommendationSection: View {
    @EnvironmentObject private var authState: AuthState
    @Binding var popularItems: [WorkoutItem]
    let bodyParts: [String]
    let recommendations: [String: [String]]
    
    func addworkout() {
        popularItems.append(WorkoutItem.MOCK_WORKOUT.cloneWithNewID())
        Task {
            await authState.storeAllWorkouts(workouts: popularItems)
        }
    }
    
    /*@ViewBuilder
    private var workoutDestination: some View {
        if let index = selectedWorkoutIndex {
            EditWorkout(item: $popularItems[index])
        } else {
            EmptyView()
        }
    } */
    

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recommendations")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(bodyParts, id: \.self) { item in
                        NavigationLink(destination: DetailView(title: item)) {
                            RecommendationCard(title: item, exercises: recommendations[item] ?? [])
                                .contextMenu{
                                    Button {
                                        withAnimation {
                                            popularItems.append(makenewRoutine(category: item,exercise_titles: recommendations[item] ?? [] ))
                                            Task {
                                                await authState.storeAllWorkouts(workouts: popularItems)
                                            }
                                            
                                        }
                                    } label: {
                                        Label("Add to My Workouts", systemImage: "plus.square.fill.on.square.fill")
                                        
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecommendationCard: View {
    @EnvironmentObject private var authState: AuthState
    
    let title: String
    let exercises: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.green]),
                    startPoint: .leading,
                    endPoint: .trailing))
                .frame(width: 50, height: 5)
                .cornerRadius(2.5)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            Divider().background(Color.gray)

            ForEach(0..<min(exercises.count, 3), id: \.self) { i in
                Text(exercises[i])
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding()
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.sRGB, white: 0.15, opacity: 1))
                .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

/*struct CategorySection: View {
    @EnvironmentObject private var authState: AuthState
    let categories: [String]
    let SelectCategory: (String?) -> Void
    @State private var selectedCategory: String? = nil

    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .font(.system(.subheadline, design: .rounded).weight(selectedCategory == category ? .semibold : .regular))
                            .foregroundColor(selectedCategory == category ? .blue : .gray)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? Color.cyan : Color.gray.opacity(0.1))
                            )
                            .onTapGesture {
                                selectedCategory = category
                                SelectCategory(category)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
} */




struct PopularSection: View {
    @EnvironmentObject private var authState: AuthState
    @Binding var popularItems: [WorkoutItem]

    @State private var selectedWorkoutIndex: Int? = nil
    @State private var beginworkoutindex: Int? = nil

    func addworkout() {
        popularItems.append(WorkoutItem.MOCK_WORKOUT.cloneWithNewID())
        Task {
            await authState.storeAllWorkouts(workouts: popularItems)
        }
    }

    func deleteWorkout(routine: WorkoutItem) {
        if let index = popularItems.firstIndex(where: { $0.id == routine.id }) {
            popularItems.remove(at: index)
        }
        Task {
            await authState.deleteWorkout(workout: routine)
        }
    }

    // Navigation destinations
    @ViewBuilder
    private var workoutDestination: some View {
        if let index = selectedWorkoutIndex {
            EditWorkout(item: $popularItems[index])
        } else {
            //
        }
    }

    @ViewBuilder
    private var beginworkout: some View {
        if let index = beginworkoutindex {
            BeginRoutine(routine: $popularItems[index])
        } else {
           //
        }
    }

    // Manual grid layout
    private func rowsOfTwo<T>(_ data: [T]) -> [[T]] {
        stride(from: 0, to: data.count, by: 2).map {
            Array(data[$0..<min($0 + 2, data.count)])
        }
    }
    
    //width of every card using the padding used
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing: CGFloat = 16 * 3 // Padding + HStack spacing
        return (screenWidth - totalSpacing) / 2
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Text("My Programs")
                    .font(.title2)
                    .bold()
                Spacer()
                Button {
                    withAnimation { addworkout() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .shadow(radius: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            // Manual grid layout: 2 columns
            VStack(spacing: 16) {
                ForEach(rowsOfTwo(popularItems).indices, id: \.self) { rowIndex in
                    HStack(spacing: 16) {
                        let row = rowsOfTwo(popularItems)[rowIndex]

                        ForEach(row.indices, id: \.self) { columnIndex in
                            let index = rowIndex * 2 + columnIndex

                            PopularCard(item: $popularItems[index])
                                .frame(width: cardWidth)
                                .onTapGesture {
                                    beginworkoutindex = index
                                }
                                .contextMenu {
                                    Button {
                                        selectedWorkoutIndex = index
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        deleteWorkout(routine: popularItems[index])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }

                        // Fill out the second column when only 1 item in the row
                        if row.count == 1 {
                            Color.clear
                                .frame(width: cardWidth)
                        }
                    }
                }
            }
            .padding(.horizontal)


        }
        // Navigation destinations outside any lazy container
        .navigationDestination(isPresented: Binding(
            get: { selectedWorkoutIndex != nil },
            set: { if !$0 { selectedWorkoutIndex = nil } }
        )) {
            workoutDestination
        }
        .navigationDestination(isPresented: Binding(
            get: { beginworkoutindex != nil },
            set: { if !$0 { beginworkoutindex = nil } }
        )) {
            beginworkout
        }
    }
}



struct PopularCard: View {
    @EnvironmentObject private var authState: AuthState
    @Binding var item: WorkoutItem
    
    //needed to format the date properly
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E yyyy-MM-dd HH:mm"
        return formatter.string(from: item.time)
    }
    
    private var categoryImageName: String {
        switch item.category {
        case "Abdominals":
            return "AbsIcon"
        case "Abductors":
            return "Abductor Machine"
        case "Adductors":
            return "Abductor Machine"
        case "Biceps":
            return "BicepIcon"
        case "Calves":
            return "CalvesIcon"
        case "Chest":
            return "ChestMuscleIcon"
        case "Forearms":
            return "forearms"
        case "Glutes":
            return "glutes"
        case "Hamstrings":
            return "Prone Curl Leg Machine"
        case "Lats":
            return "LatIcon"
        case "Lower Back":
            return "LowerBackIcon"
        case "Middle Back":
            return "Lower back muscle"
        case "Neck":
            return "Upper back muscle"
        case "Quadriceps":
            return "quadriceps"
        case "Shoulders":
            return "Leverage Shoulder Press"
        case "Traps":
            return "Upper back muscle"
        case "Triceps":
            return "TricepIcon"
        default:
            return "questionmark.circle"
        }
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 75)
                
                Image(categoryImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 55)
                    .foregroundColor(.white)
            }
            
            Text(item.title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 2){
                ForEach(item.description.prefix(4), id: \.self){ workout in
                    Text(workout.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxHeight: 110) // Adjust based on how many lines you'd like to show
            
            
            Spacer()
            
            HStack {
                
                Text(formattedDate)
                    .font(.caption).lineLimit(2)
                    .truncationMode(.tail)
                Spacer()
                Text(formatTime(Double(item.duration)))
                    .font(.caption)
            }
            .foregroundColor(.gray)
        }
        .padding()
        .frame(height: 250)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}


struct DetailView: View {
    @EnvironmentObject private var authState: AuthState
    let title: String

    var body: some View {
        VStack {
            Text("Details for \(title)")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle(title)
    }
}

struct EditWorkout: View {
    @EnvironmentObject private var authState: AuthState
    @Binding var item: WorkoutItem
    @State private var showPicker = false
    @State private var selectedExercise = ""
    @State private var searchText = ""
    @State private var pre = Preprocessor.shared

    private var filteredExercises: [String] {
        if searchText.isEmpty {
            return pre.titles
        } else {
            return pre.titles.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Workout Info
                Section(header: Text("Workout Info")) {
                    TextField("Title", text: $item.title)
                }

                // Category Picker
                Section(header: Text("Category")) {
                    Picker("Category", selection: $item.category) {
                        ForEach(pre.bodyPartCats, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }

                // Exercises
                Section(
                    header:
                        HStack {
                            Text("Exercises")
                            Spacer()
                            Button {
                                withAnimation {
                                    showPicker.toggle()
                                    searchText = ""
                                    selectedExercise = ""
                                }
                            } label: {
                                Image(systemName: showPicker ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .shadow(radius: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                ) {
                    // Search and Add Section (showPicker first)
                    if showPicker {
                        VStack(alignment: .leading, spacing: 10) {
                            // Search Bar
                            TextField("Search exercises...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 10)
                                .foregroundStyle(.secondary)

                            // Filtered List
                            
                            Section{
                                    ScrollView {
                                        ForEach(filteredExercises, id: \.self) { ex in
                                            HStack {
                                                Text(ex)
                                                    .padding(8)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .foregroundColor(.secondary)
                                                    .cornerRadius(6)
                                                    .onTapGesture {
                                                        selectedExercise = ex
                                                    }
                                                if selectedExercise == ex {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.accentColor)
                                                }
                                            }
                                            .background(selectedExercise == ex ? Color.accentColor.opacity(0.2) : Color.clear)
                                          Divider()
                                        }
                                    }
                                  }
                            .frame(height: 150)
                            .cornerRadius(8)

                            // Confirm Add Button
                            Button(action: {
                                guard !selectedExercise.isEmpty else { return }
                                if !item.description.contains(where: { $0.name == selectedExercise }) {
                                    let newWorkout = Workout(
                                        id: UUID().uuidString,
                                        name: selectedExercise,
                                        sets: [1: SetDetail(prev: 60, rep: 10)]
                                    )
                                    item.description.append(newWorkout)
                                    Task {
                                        await authState.StoreWorkouts(workout: item)
                                    }
                                }
                                withAnimation {
                                    showPicker = false
                                    searchText = ""
                                    selectedExercise = ""
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Add Exercise")
                                        .bold()
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 6)
                            .background(selectedExercise.isEmpty ? Color.gray.opacity(0.2) : Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                            .disabled(selectedExercise.isEmpty)
                        }
                        .padding(.vertical, 4)
                    }
                    else{
                        // Current Exercises List
                        ForEach(item.description, id: \.id) { workout in
                            Text("• \(workout.name)")
                                .padding(.vertical, 4)
                        }
                        .onDelete {
                            item.description.remove(atOffsets: $0)
                        }
                        .onMove {
                            item.description.move(fromOffsets: $0, toOffset: $1)
                        }
                    }

                    
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .animation(.easeInOut, value: showPicker)
            .onChange(of: item.title) {
                Task {
                    await authState.StoreWorkouts(workout: item)
                }
            }
            .onChange(of: item.category) {
                Task {
                    await authState.StoreWorkouts(workout: item)
                }
            }
            .onChange(of: item.description) { 
                Task {
                    await authState.StoreWorkouts(workout: item)
                }
            }
        }
    }
}




/*struct CreateWorkout_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var item = WorkoutItem(id: UUID().uuidString,
            title: "Title 1",
            description: ["Push Ups 3 x 12", "Lunges 3 x 10"],
            likes: 100,
            duration: 30 ,category: "Back"
        )

        var body: some View {
            NavigationStack {
                EditWorkout(item: $item)
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
} */




