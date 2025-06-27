//
//  Meal.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 23/05/2025.
//


import SwiftUI



// MARK: - ViewModel


// MARK: - Date Extensions

    

// MARK: - Main View
struct MealTrackingView: View {
    @EnvironmentObject private var tracker: MealTracker
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var tabManager: TabSelectionManager
    @State var selectedMonthIndex: Int = Calendar.current.component(.month, from: Date()) - 1
    @State private var selectedDate = Date()
    @State private var showingMealForm = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var carbsConsumed = 0
    @State private var carbsGoal = 0
    @State private var proteinConsumed = 0
    @State private var proteinGoal = 0
    @State private var fatConsumed = 0
    @State private var fatGoal = 0
    @State private var past_days = false

    
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Date Header
                    dateHeader
                    
                    // 2. Week Selector
                    weekSelector
                    
                    Divider()
                    
                    // 3. Daily Summary
                    dailySummary
                    
                    // 4. Meal Sections
                    mealSections
                }
                .padding()
            }
            .task({
                await authState.fetchAllMeals()
            })
            .sheet(isPresented: $showingMealForm) {
                AddMealView(
                    onSave: { meal in
                        tracker.addMeal(meal)
                    }, mealType: selectedMealType,
                    date: selectedDate
                ).onDisappear {
                    authState.foodsuggestions = []
                }
            }.sheet(isPresented: $past_days) {
                VStack{
                    monthSelector
                }.frame(maxHeight: .infinity,alignment: .topLeading)
                
            }
    }
    
    private var dateHeader: some View {
        HStack {
            Text("\(formattedDate)")
                .font(.title2.bold())
            Spacer()
            Button(action: {
                past_days = true
            }) {
                Image(systemName: "calendar.badge.plus")
                    .imageScale(.large)
                    .padding()
            }
            .contentShape(Rectangle())
        }
        .padding(.trailing)
    }
    
    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(selectedDate.weekDates, id: \.self) { date in
                    VStack(spacing: 5) {
                        Text(date.dayAbbreviation)
                            .font(.caption)
                            .foregroundColor(date.isWeekend ? .red : .secondary)
                        
                        Text("\(date.dayNumber)")
                            .font(.body.bold())
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(date.isSameDay(as: selectedDate) ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(date.isSameDay(as: selectedDate) ? .white : .primary)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(date.isSameDay(as: selectedDate) ? 1 : 0), lineWidth: 2)
                            )
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
        }
    }

    
    @ViewBuilder
    private var dailySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Daily Total
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Daily Total: \(tracker.dailyCalTot) kcal")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            ProgressView(
                value: Double(tracker.dailyTotal(for: selectedDate)),
                total: Double(tracker.dailyCalTot)
            )
            .animation(.easeIn(duration: 2), value:
                        tracker.dailyTotal(for: selectedDate))
            .tint(.orange)
            .scaleEffect(x: 1, y: 1.5, anchor: .center)
            .padding()
            
            Divider()
            
            // Macros Section
            HStack {
                macroComponent(
                    icon: "carrot.fill",
                    label: "Carbs",
                    consumed: Int(tracker.carbTotal(for: selectedDate).rounded()),
                    goal: authState.currentuser?.carbsMark ?? 0,
                    color: .green
                )
                
                macroComponent(
                    icon: "fish.fill",
                    label: "Protein",
                    consumed: Int(tracker.proteinTotal(for: selectedDate).rounded()),
                    goal: authState.currentuser?.proteinMark ?? 0,
                    color: .red
                )
                
                macroComponent(
                    icon: "drop.fill",
                    label: "Fat",
                    consumed: Int(tracker.fatTotal(for: selectedDate).rounded()),
                    goal: authState.currentuser?.fatMark ?? 0,
                    color: .yellow
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }

    // Helper View for each macro component
    @ViewBuilder
    private func macroComponent(icon: String, label: String, consumed: Int, goal: Int, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            MacroTracker(consumed: consumed, goal: goal, colour: color)
                .padding()
            
            Text("\(consumed) / \(goal) g")
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    
    
    private var mealEntries: [MealEntry] {
        tracker.dailyGoals.map {
            MealEntry(id: $0.key.id, type: $0.key, targetCalories: $0.value)
        }
    }

    
    private var mealSections: some View {
        ForEach(mealEntries) { entry in
            let type = entry.type
            let range = entry.targetCalories
            let meals = tracker.meals[selectedDate.startOfDay]?.filter { $0.type == type } ?? []
            let total = meals.reduce(0) { $0 + $1.calories }.rounded()
            let fraction = min(total / Double(range), 1)
            let dynamicColor = fraction >= 1 ? Color.red : Color.orange

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label(entry.rawValue, systemImage: "fork.knife")
                        .font(.headline)
                        .foregroundColor(dynamicColor)
                    Spacer()
                    Text("\(Int(total))/\(range) kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress Bar
                ProgressView(value: total, total: Double(range))
                    .tint(dynamicColor)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    .animation(.easeInOut(duration: 2), value: total)

                // Meal List
                if !meals.isEmpty {
                    ForEach(meals) { meal in
                        HStack {
                            Text(meal.name)
                            Spacer()
                            Text("\(Int(meal.calories.rounded())) kcal")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Add Meal Button
                Button {
                    selectedMealType = type
                    showingMealForm = true
                } label: {
                    Label("Add Meal", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(dynamicColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
    }
    
    private var monthSelector: some View {
       
        let calendar = Calendar.current
        
        // -1 is used as Janurary would be the first month of the year but in the array it would be position 0
       
        
        var startofMonth: Date = calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: selectedMonthIndex + 1, day: 1))!
        
        //CHANGES WHEN THE PICKER CHANGES
        var monthDates:[Date]{startofMonth.monthDates }// your computed property from earlier
        
        let columns = Array(repeating: GridItem(.flexible()), count: 7) // 7 days per week
        
        let formatter = DateFormatter().monthSymbols
        
       
        //calendar.date(from: calendar.dateComponents([.year, .month], from: self))
        
        
        return VStack(alignment: .leading){
            
            if let months = formatter{
                Picker("", selection: $selectedMonthIndex) {
                    ForEach(0..<months.count, id:\.self) { index in
                        Text(months[index]).tag(index)
                    }
                }.padding(.bottom)
            }
            
            //DISPLAYS THE ACTUAL CALENAR
            LazyVGrid(columns: columns, spacing: 10) {
                // Optional: show weekday headers
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday.prefix(2))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }

                // Align first day to correct weekday
                let firstDate = monthDates.first ?? Date()
                let firstWeekday = calendar.component(.weekday, from: firstDate) // 1 = Sunday, 7 = Saturday

                ForEach(1..<(firstWeekday), id: \.self) { _ in
                    Color.clear.frame(height: 40) // Empty space for days before first day
                }

                // Show actual days
                ForEach(monthDates, id: \.self) { date in
                    let isSelected = date.isSameDay(as: selectedDate)
                    Text("\(date.dayNumber)")
                        .font(.body.bold())
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Color.blue : Color.clear)
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Circle())
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                                past_days = false
                            }
                        }
                }
            }
            
        }
        .padding()
    }

    
    private var formattedDate: String {
        if Date().isSameDay(as: selectedDate) {
            return "Today"
        }
        else{
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE d MMM yyyy"
            return formatter.string(from: selectedDate)
        }
        
    }
}



//BREAKING TO SOLVE COMPILER TIMING OUT ERROR
extension AddMealView {
  @ViewBuilder
  private var suggestionList: some View {
      if !authState.foodsuggestions.isEmpty {
          Spacer()
          Section(header:Text("Results Matched").font(.body).foregroundStyle(.gray)) {
                  ScrollView {
                      ForEach(authState.foodsuggestions, id: \.self) { food in
                        HStack {
                          Text(food.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                          Text(String(format: "%.0f kcal", food.calories))
                            .foregroundColor(.secondary)
                        }
                        //.contentShape(Rectangle())
                        .onTapGesture { pick(food) }
                        Divider()
                      }
                  }
                  .frame(height: 250) // fix the dropdown height
                }
    }
  }
}


// MARK: - Add Meal View
struct AddMealView: View {
  @EnvironmentObject private var authState: AuthState

  //closure to trigger save command
  var onSave: (Meal) -> Void
  
  let mealType:MealType // used to for display purposes
  let date: Date
    
  @FocusState private var isQuantityFocused: Bool
  @State private var name = ""
  @State private var calories = ""
  @State private var carb = ""
  @State private var fat = ""
  @State private var protein = ""
  @State private var unit: FoodUnit = .grams
  @State private var quantity = ""
  @State private var searchstring = ""
  @State private var notes = ""
  @Environment(\.dismiss) private var dismiss
    
// to store the original values
 @State private var originalMacros: (protein: Double, carb: Double, fat: Double, calories: Double)? = nil

    private func pick(_ food: Food) {
        name = food.name
        calories = String(food.calories.rounded())
        carb = String(food.carb.rounded())
        fat = String(food.fat.rounded())
        protein = String(food.protein.rounded())
        originalMacros = (
            food.protein.rounded(),
            food.carb.rounded(),
            food.fat.rounded(),
            food.calories.rounded()
        )

        // Clear suggestions but NOT searchstring to prevent onChange
        authState.foodsuggestions = []
    }

    
    private func calculateMacros(_ quantity: String, _ unit: FoodUnit) {
        guard let base = originalMacros else { return }

        // Handle empty or invalid input: revert to base values
        guard let quantity = Double(quantity), quantity > 0 else {
            protein = String(base.protein)
            carb = String(base.carb)
            fat = String(base.fat)
            calories = String(base.calories)
            return
        }

        switch unit {
        case .grams:
            protein = String(Int(ceil((base.protein / 100) * quantity)))
            carb = String(Int(ceil((base.carb / 100) * quantity)))
            fat = String(Int(ceil((base.fat / 100) * quantity)))
            calories = String(Int(ceil((base.calories / 100) * quantity)))
            
        case .ounces:
            let gramsQuantity = quantity * 28.3495
            protein = String(Int(ceil((base.protein / 100) * gramsQuantity)))
            carb = String(Int(ceil((base.carb / 100) * gramsQuantity)))
            fat = String(Int(ceil((base.fat / 100) * gramsQuantity)))
            calories = String(Int(ceil((base.calories / 100) * gramsQuantity)))
            
        case .pounds:
            let gramsQuantity = quantity * 453.592
            protein = String(Int(ceil((base.protein / 100) * gramsQuantity)))
            carb = String(Int(ceil((base.carb / 100) * gramsQuantity)))
            fat = String(Int(ceil((base.fat / 100) * gramsQuantity)))
            calories = String(Int(ceil((base.calories / 100) * gramsQuantity)))
        }

    }


  var body: some View {
    NavigationStack {
      Form {
          Section(header: Text("Meal Details")) {
              // Search Field (not actual meal name)
              TextField("Search food...", text: $searchstring)
                  .onChange(of: searchstring) {
                      Task { await authState.fetchFoodSuggestions(matching: searchstring.lowercased()) }
                  }
                  .autocorrectionDisabled()

              // Suggestions below the search field
              suggestionList

              // Actual selected name (filled when a suggestion is picked)
              if !name.isEmpty {
                  TextField("Selected food", text: $name)
                      .disabled(true)
                      .foregroundColor(.gray)
              }

              // Quantity + Unit
              HStack {
                  TextField("Quantity", text: $quantity)
                      .onSubmit {
                          calculateMacros(quantity, unit)
                      }

                  HStack {
                      Text("Unit")
                      Picker("", selection: $unit) {
                          ForEach(FoodUnit.allCases) { unit in
                              Text(unit.rawValue).tag(unit)
                          }
                      }
                      .labelsHidden()
                  }
              }
          }

          
          Text("MACRO BREAKDOWN").font(.headline).bold().listRowBackground(Color.clear)
          
          //MACRO NUTRIENT BREAKDOWN
          Section(header: Text("Calories from Food")){
              TextField("Estimated Calories/ kcal", text: $calories)
                .keyboardType(.numberPad)
          }
          
          Section(header: Text("Carbonhydrate Content")){
              TextField("Estimated Carbs /g", text: $carb)
                .keyboardType(.numberPad)
          }
          
          Section(header: Text("Protein Content")){
              TextField("Estimated Protein /g", text: $protein)
                .keyboardType(.numberPad)
          }
          
          Section(header: Text("Fat Content")){
              TextField("Estimated Fat /g", text: $fat)
                .keyboardType(.numberPad)
          }
          //END OF MACRO BREAKDOWN
          


          Section(header: Text("Notes")) {
          TextEditor(text: $notes)
            .frame(minHeight: 100)
        }
      }
      .navigationTitle("Add \(mealType.rawValue)")
      .toolbar {
          ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") { dismiss() }
          }
          ToolbarItem(placement: .confirmationAction) {
              Button("Save") {
                  if let caloriesDoub = Double(calories) {
                      let meal = Meal(
                          type: mealType,
                          name: name,
                          calories: caloriesDoub,
                          carb: Double(carb)?.rounded() ?? 0,
                          protein : Double(protein)?.rounded() ?? 0,
                          fat: Double(fat)?.rounded() ?? 0,
                          date: date,
                          notes: notes,
                          quantity: Double(quantity) ?? 0
                      )
                      onSave(meal)
                  }
                  dismiss()
              }
              .disabled(name.isEmpty || calories.isEmpty)
          }
      }
    }
  }
}




