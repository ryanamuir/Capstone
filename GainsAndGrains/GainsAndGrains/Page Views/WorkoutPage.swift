import SwiftUI
import UIKit
import CoreML
import FirebaseFirestore


func formatTime(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60
    return String(format: " %d:%02d:%02d",hours, minutes, seconds)
}

struct BeginRoutine: View {
    @EnvironmentObject private var manager:HealthManager
    @EnvironmentObject private var authState: AuthState
    @Binding var routine: WorkoutItem
    @State private var startTime: Date = Date()
    @State private var endtime : Date = Date()
    @State private var timelapse: TimeInterval = 0
    @State private var progressStates: [String:ExerciseProgress] = [:]
    @State private var showCompletionAlert = false
    @State private var tempduration = 0
    @State private var showRestTimer = false
    
    private func checkifCompleted() {
        if progressStates.values.allSatisfy({ $0.isComplete }) {
            endtime = Date()
            timelapse = endtime.timeIntervalSince(startTime)
            tempduration = Int(timelapse)
            
            
            
            
            print("\(routine.duration)")

            // ✅ Real logic should be:
            // routine = routine.updated(duration: Int(timelapse))
            

            showCompletionAlert = true
        }
    }
    

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing:30){
                    

                    ForEach($routine.description, id: \.self) { $exercise in
                        ExerciseCards(exercise: $exercise,
                                      progress: Binding(
                                        get: {progressStates[exercise.id] ?? ExerciseProgress(sets: exercise.sets.count)},
                                        set: { newValue in progressStates[exercise.id] = newValue
                                            checkifCompleted()
                        }))
                    }
                }
                .padding(.top)
                .alert(isPresented: $showCompletionAlert) {
                    Alert(
                        title: Text("Workout Completed!"),
                        message: Text("Time Taken: \(formatTime(timelapse))"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationTitle((routine.title))
            .onAppear{
                
                tempduration = routine.duration
                endtime = routine.time
                for exercise in routine.description {
                    //create a specific id for each exercise in the routine
                    progressStates[exercise.id] = ExerciseProgress(sets:exercise.sets.count)
                }
            }
            .onDisappear {
           routine.duration = tempduration
           routine.time = endtime
           
            Task {
                await authState.StoreWorkouts(workout: routine)

                // 🚀 Call the callback once saving is done
                
            }
        }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            startTime = Date()
                        }) {
                            Label("Restart Timer", systemImage: "play")
                        }
                        
                        Button(action: {
                            showRestTimer = true
                        }) {
                            Label("Rest Timer", systemImage: "timer")
                        }
                    } label: {
                        
                        Image(systemName: "ellipsis")
                            .font(.callout)
                            .padding(12)
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }
                }
            }
            .sheet(isPresented: $showRestTimer) {
                RestTimer()
            }

        
    }
    
    
}

struct ExerciseCards: View {
    @Binding var exercise: Workout
    @Binding var progress: ExerciseProgress
    @State private var isExpanded = false
    @State private var tempReps: [Int: SetDetail] = [:]

    private func toggleHighlight(for set: Int) {
        if progress.highlighted.contains(set) {
            progress.highlighted.remove(set)
        } else {
            progress.highlighted.insert(set)
        }
    }

    private func delete_set(for set: Int) {
        
        if progress.highlighted.contains(set) {
            progress.highlighted.remove(set)
        }
        tempReps.removeValue(forKey: set)
        
        
        let remaining_key = tempReps.keys.sorted() // THE REAMINNG KEYS as an array eg. [1,2,3]
        var newTempReps: [Int:SetDetail] = [:] // A NEW TEMP-REPS
        
        /*enumaerated converts array into tuple where first part is the
         position in the array and second represents the actual element */
        for (index,oldKey) in remaining_key.enumerated(){
            newTempReps[index + 1] = tempReps[oldKey]
            //Since it is consecutive number the index + 1 represents the new key and the old key is used to access the value from dictionary
        }
        tempReps = newTempReps
        progress.sets = tempReps.keys.count
        
        
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading) {
                // Headings
                HStack {
                    Text("Set").frame(width: 60).multilineTextAlignment(.center).bold()
                    Spacer()
                    Text("Prev").frame(width: 60).multilineTextAlignment(.center).bold()
                    Spacer()
                    Text("Reps").frame(width: 60).multilineTextAlignment(.center).bold()
                    Spacer()
                    Spacer(minLength: 60)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                // List of sets with swipe actions
                List {
                    ForEach(tempReps.keys.sorted(), id: \.self) { set in
                        HStack {
                            Text("\(set)")
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .padding(.leading, 2.0)

                            Spacer()

                            // Prev weight
                            TextField("-", value: Binding(
                                get: { tempReps[set]?.prev ?? 0 },
                                set: { tempReps[set]?.prev = $0 }
                            ), formatter: NumberFormatter())
                                .foregroundColor(Color.gray.opacity(0.5))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
                                .shadow(radius: 1)

                            Spacer()

                            // Reps
                            TextField("Reps", value: Binding(
                                get: { tempReps[set]?.rep ?? 0 },
                                set: { tempReps[set]?.rep = $0 }
                            ), formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
                                .shadow(radius: 1)

                            Spacer()

                            // Checkmark
                            Image(systemName: "checkmark")
                                .frame(width: 60, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                )
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    toggleHighlight(for: set)
                                }

                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        //.padding(.vertical, 4)
                        .background(progress.highlighted.contains(set) ? Color.accentColor.opacity(0.4) : Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color(.systemGray6))
                        .listRowSeparator(.hidden)
                        .swipeActions {
                            Button(role: .destructive) {
                                delete_set(for: set)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .frame(height: CGFloat(tempReps.count) * 60) // adjust as needed
                .listStyle(PlainListStyle())
                .scrollDisabled(true) // disable scrolling since it’s nested

                Button(action: {
                    let newSet = (tempReps.keys.max() ?? 0) + 1
                    withAnimation {
                        tempReps[newSet] = SetDetail(prev: 0, rep: 10)
                        
                        //UPDATE THE NUMBER OF SETS IN THE PROGRESS TRACKER
                        progress.sets += 1
                    }
                }) {
                    HStack {
                        Spacer()
                        Label("Add Set", systemImage: "plus")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
            .padding(.top, 10)

        }
        // LABEL FOR THE DISCLOSURE GROUP
        label: {
            if isExpanded {
                Text(exercise.name)
                    .font(.title2)
                    .bold()
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .bold()
                    ForEach(tempReps.keys.sorted(), id: \.self) { set in
                        Text("\(set) • \(tempReps[set]?.rep ?? 0) Reps")
                            .font(.subheadline)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
        .padding(.horizontal)
        .onAppear {
            tempReps = exercise.sets
        }
        .onDisappear {
            exercise.sets = tempReps
        }
    }
}



/*struct ExerciseCards_Previews: PreviewProvider {
    struct Wrapper: View {
        @State private var workout = Workout(id: UUID().uuidString,name: "Barbell Bench Press", sets: [1: 10, 2: 8])

        var body: some View {
            ExerciseCards(exercise: $workout,)
        }
    }

    static var previews: some View {
        Wrapper()
    }
} */





