//
//  User.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 10/05/2025.
//
import Foundation

struct User: Identifiable,Codable{
    let id: String
    let fullname: String
    let age : Int
    let gender:String
    let height: Int
    let weight: Int
    let fitnessGoal : String
    let dietaryPreference: String
    let activityLevel: String
    let equipmentAccess : String
    let mealsPerDay: Int
    
    var initials:String{
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullname){
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return "NA"
    }
}

extension User{
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Charles Leclerc", age: 27,gender: "Male",height: 50,weight: 100, fitnessGoal: "Strength",dietaryPreference: "None",activityLevel:"Sedentary",equipmentAccess: "None",mealsPerDay: 2)
}

