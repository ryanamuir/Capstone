//
//  User.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 10/05/2025.
//
import Foundation
import SwiftUI
import CoreML

struct User: Identifiable, Codable {
    let id: String
    let fullname: String
    let age: Int
    let gender: String            // e.g. "Male" or "Female"
    let height: Int               // cm
    let weight: Int               // kg
    let fitnessGoal: String       // e.g. "Lose weight"
    let dietaryPreference: String
    let activityLevel: String     // e.g. "Moderately active"
    let equipmentAccess: String
    let mealsPerDay: Int
    var mealTargets: [MealType:Int]?
    
    var initials:String{
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname){
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return "NA"
    }
    
    var manualTargetCalories: Int?

    /// Basal metabolic rate (Mifflin–St Jeor / Harris–Benedict), rounded up to nearest kcal
    var bmr: Int {
        let raw: Double
        switch gender {
        case "Male":
            raw = 88.362
                + 13.397 * Double(weight)
                + 4.799  * Double(height)
                - 5.677  * Double(age)
        case "Female":
            raw = 447.593
                + 9.247  * Double(weight)
                + 3.098  * Double(height)
                - 4.330  * Double(age)
        default:
            raw = 0
        }
        return Int(ceil(raw))
    }

    /// Total daily energy expenditure, rounded up to nearest kcal
    var tdee: Int {
        let factor: Double
        switch activityLevel {
        case "Sedentary":         factor = 1.2
        case "Lightly active":    factor = 1.375
        case "Moderately active": factor = 1.55
        case "Very active":       factor = 1.725
        default:                  factor = 1.0
        }
        return Int(ceil(Double(bmr) * factor))
    }

    /// Target calorie intake: uses manual override if set, otherwise formula; rounded up
    var targetCaloriesIntake: Int {
        if let manual = manualTargetCalories {
            return manual
        }
        let raw: Double
        switch fitnessGoal {
        case "Lose weight":       raw = Double(tdee) * 0.85
        case "Build muscle":      raw = Double(tdee) + 500
        case "Improve endurance": raw = Double(tdee) + 200
        case "General fitness":   raw = Double(tdee)
        default:                  raw = Double(tdee)
        }
        return Int(ceil(raw))
    }

    /// Protein target (grams), rounded up
    var proteinMark: Int {
        let ratio: Double
        switch fitnessGoal {
        case "Lose weight", "Build muscle": ratio = 0.3
        case "Improve endurance":           ratio = 0.2
        case "General fitness":             ratio = 0.25
        default:                            ratio = 0.0
        }
        let grams = (Double(targetCaloriesIntake) * ratio) / 4.0
        return Int(ceil(grams))
    }

    /// Fat target (grams), rounded up
    var fatMark: Int {
        let ratio: Double
        switch fitnessGoal {
        case "Lose weight":       ratio = 0.3
        case "Build muscle":      ratio = 0.2
        case "Improve endurance": ratio = 0.2
        case "General fitness":   ratio = 0.3
        default:                  ratio = 0.0
        }
        let grams = (Double(targetCaloriesIntake) * ratio) / 9.0
        return Int(ceil(grams))
    }

    /// Carbohydrates target (grams), rounded up
    var carbsMark: Int {
        let ratio: Double
        switch fitnessGoal {
        case "Lose weight":       ratio = 0.4
        case "Build muscle":      ratio = 0.5
        case "Improve endurance": ratio = 0.6
        case "General fitness":   ratio = 0.45
        default:                  ratio = 0.0
        }
        let grams = (Double(targetCaloriesIntake) * ratio) / 4.0
        return Int(ceil(grams))
    }

    /// Recommended calories to burn per day, rounded up
    var targetCalBurned: Int {
        let raw: Double
        switch fitnessGoal {
        case "Lose weight":       raw = 500
        case "Build muscle":      raw = 300
        case "Improve endurance": raw = 800
        case "General fitness":   raw = 400
        default:                  raw = 0
        }
        return Int(ceil(raw))
    }
}



extension User{
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Charles Leclerc", age: 27,gender: "Male",height: 50,weight: 100, fitnessGoal: "Strength",dietaryPreference: "None",activityLevel:"Sedentary",equipmentAccess: "None",mealsPerDay: 2)
}


struct WorkoutItem: Identifiable, Hashable,Codable{
    let id : String
    var title: String
    var description: [Workout]
    var time: Date
    var duration: Int
    var category : String
}

extension WorkoutItem{
    static var MOCK_WORKOUT = WorkoutItem(id: UUID().uuidString, title: "Default", description: [Workout.MOCK_WORKOUT], time: Date(), duration: 0, category: "Chest")

    //function to clone the mock workouts in order to add new workouts to the
    func cloneWithNewID() -> WorkoutItem {
            WorkoutItem(
                id: UUID().uuidString,
                title: self.title,
                description: self.description,
                time: self.time,
                duration: self.duration,
                category: self.category
            )
        }
    
    func createnewWorkout(name:String, workout: [Workout])-> WorkoutItem{
        WorkoutItem(
            id:UUID().uuidString,
            title: name + " " + "Routine",
            description: workout,
            time: self.time,
            duration: self.duration,
            category: name
        )
    }
    
}

struct SetDetail: Codable,Hashable{
    var prev: Int
    var rep : Int
    
}

struct Workout: Identifiable, Hashable,Codable{
    let id: String
    var name : String
    var sets : [Int:SetDetail]
    
}

extension Workout{
    static var MOCK_WORKOUT = Workout(id:UUID().uuidString, name: "Barbell Bench", sets: [1:SetDetail(prev: 60, rep: 8)])
    
    // creates a new workout with a different name but default sets
    func cloneWithnewName(title: String) -> Workout {
        Workout(
                id: UUID().uuidString,
                name: title,
                sets: self.sets
            )
        }
}


extension MLMultiArray {
    func topKIndices(_ k: Int) -> [Int] {
        let pairs: [(Int, Double)] = (0..<self.count).map { ($0, self[$0].doubleValue) }
        let sorted = pairs.sorted { $0.1 > $1.1 }
        return Array(sorted.prefix(k).map { $0.0 })
    }
}

struct ExerciseProgress: Codable,Hashable{
    var sets:Int
    var highlighted : Set<Int> = []
    
    var isComplete: Bool{
        sets == highlighted.count && sets>0
    }
}





enum MealType: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case preworkout = "Pre-Workout"
    case postworkout = "Post-Workout"
    var id: String { self.rawValue }
}

// MARK: - Data Models
//ACTUAL MEAL DATA
struct Meal: Identifiable, Codable {
    var id : String = UUID().uuidString
    var type: MealType
    var name: String
    var calories: Double
    var carb: Double
    var protein: Double
    var fat: Double
    var date: Date
    var notes: String
    var quantity: Double
    
    
    
}

struct MealEntry: Identifiable {
    let id: String
    let type: MealType
    let targetCalories: Int
    
    var rawValue: String { type.rawValue }
}

//USED WHEN FETCHING SUGGESTIONS
struct Food: Codable,Hashable{
  var name: String
  var calories: Double
  var carb:Double
  var protein:Double
  var fat:Double
}


enum FoodUnit: String, CaseIterable, Identifiable {
  case grams = "g"
  case ounces = "oz"
  case pounds = "lbs"
  
  var id: Self { self }
}


struct WorkoutDescription: Codable, Hashable {
    var Title: String
    var Desc: String

}

