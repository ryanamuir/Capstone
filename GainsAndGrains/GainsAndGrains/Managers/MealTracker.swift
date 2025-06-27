//
//  MealTracker.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 25/05/2025.
//
import Combine
import SwiftUI

//FUNCTION TO SPLIT A NUMBER EVENLY AS POSSIBLE INTO N PARTS
func splitEvenly(total: Int, into parts: Int) -> [Int] {
    guard parts > 0 else { return [] }
    let base = total / parts
    let remainder = total % parts
    
    var result = Array(repeating: base, count: parts)
    for i in 0..<remainder {
        result[i] += 1
    }
    return result
}

@MainActor
class MealTracker: ObservableObject {
  private let authState: AuthState
  @Published var meals: [Date: [Meal]] = [:]
  @Published var dailyGoals: [MealType: Int] = [:]
  @Published var dailyCalTot: Int = 0
  
  // this is used to store the link to the subscriber if not there then it will not receive updates
  private var cancellables = Set <AnyCancellable> ()

  init(authState: AuthState) {
    self.authState = authState

    // 1) Subscribe to any future changes in authState.meals
      authState.$meals
      .map { $0 ?? [:] }
      .receive(on: DispatchQueue.main)
      .assign(to: \.meals, on: self)
      .store(in: &cancellables)

    // 2) Initial fetch & setup
    Task {
      guard let user = authState.currentuser else {
        print("❌ no user yet; goals will remain empty")
        return
      }
      print("User Found")
      await authState.fetchAllMeals()
        
        
      // Note: the line below is now optional, since the Combine subscription will
      // automatically update `meals` when fetchAllMeals() sets authState.meals:
      // meals = authState.meals ?? [:]

      dailyCalTot = user.targetCaloriesIntake
      if let targets = user.mealTargets {
        dailyGoals = targets
      } else {
        let split = splitEvenly(total: user.targetCaloriesIntake, into: 3)
        dailyGoals = [
          .breakfast: split[0],
          .lunch:     split[1],
          .dinner:    split[2],
        ]
      }
    }
  }
    
    
    func addMeal(_ meal: Meal) {
      let day = Calendar.current.startOfDay(for: meal.date)
      print("\(meal)")
      meals[day, default: []].append(meal)
      Task { await authState.addMeal(meal) }
    }
    
    func dailyTotal(for date: Date) -> Double {
        meals[date.startOfDay]?.reduce(0) { $0 + $1.calories } ?? 0
    }
    
    func proteinTotal(for date: Date) -> Double {
        meals[date.startOfDay]?.reduce(0) { $0 + $1.protein } ?? 0
    }
    
    func carbTotal(for date: Date) -> Double {
        meals[date.startOfDay]?.reduce(0) { $0 + $1.carb } ?? 0
    }
    
    func fatTotal(for date: Date) -> Double {
        meals[date.startOfDay]?.reduce(0) { $0 + $1.fat } ?? 0
    }
    
}
