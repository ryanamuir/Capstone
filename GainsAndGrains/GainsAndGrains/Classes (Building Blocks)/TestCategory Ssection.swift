//
//  TestCategory Ssection.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 11/06/2025.
//
import SwiftUI

struct CategorySection_: View {
    @State private var activebar: Category_Tabs = .all
    @Binding var selectedCategory: String?
    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            CustomCategoryBar(activeBar:$activebar, SelectCategory: { category in
                
                switch category {
                case "Latissimus Dorsi": self.selectedCategory = "Lats"
                case "All Muscles" : self.selectedCategory = "All"
                default: self.selectedCategory = category
                }
                
                    
            })
        }
        .padding(.bottom,35)
    }
}

struct CustomCategoryBar: View {
    @Binding var activeBar : Category_Tabs
    let SelectCategory: (String?) -> Void
    var body: some View {
        GeometryReader{ _ in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    HStack(spacing:8){
                        ForEach(Category_Tabs.allCases, id: \.rawValue){ tab in
                            tabButton(tab)
                            
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }.padding(.bottom)
            
        }.frame(maxHeight: 60)
    }
    
    @ViewBuilder
    func tabButton(_ tab: Category_Tabs) -> some View {
        HStack(spacing:8) {
            
            //SINC THE OTHERS ARE IMAGES AND ALL IS JUST AN SYSTEM IAMGE
                Image(tab.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            
            

            if tab == activeBar {
                Text(tab.rawValue)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .transition(.opacity.combined(with: .scale)) // smooth entrance
            }
        }
        .frame(maxWidth: tab == activeBar ? .infinity : nil)
        .frame(maxHeight: .infinity)
        .padding(.horizontal,20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tab == activeBar ? tab.color : .gray.opacity(0.7))
        )
        .foregroundStyle(tab == activeBar ? Color.white : .gray)
        .onTapGesture {
            withAnimation(.bouncy(duration: 1)) {
                activeBar = tab
                SelectCategory(tab.rawValue)
            }
        }
    }
}


#Preview {
    @Previewable @State var selectedCategory: String? = "All"
    return CategorySection_(selectedCategory: $selectedCategory)
}

enum Category_Tabs: String, CaseIterable {
    case all = "All Muscles"
    case abdominals = "Abdominals"
    case abductors = "Abductors"
    case Adductors = "Adductors"
    case Biceps = "Biceps"
    case Calves = "Calves"
    case Chest = "Chest"
    case Forearms = "Forearms"
    case Glutes = "Glutes"
    case Hamstrings = "Hamstrings"
    case Lats = "Latissimus Dorsi"
    case Lowerback = "Lower Back"
    case MiddleBack = "Middle Back"
    case Neck = "Neck"
    case Quadriceps = "Quadriceps"
    case Shoulders = "Shoulders"
    case Traps = "Traps"
    case Triceps = "Triceps"
    
    var color: Color {
        switch self {
        case .all:
            return .red
        case .abdominals:
            return .blue
        case .abductors:
            return .green
        case .Adductors:
            return .orange
        case .Biceps:
            return .purple
        case .Calves:
            return .brown
        case .Chest:
            return .pink
        case .Forearms:
            return .red
        case .Glutes:
            return .blue
        case .Hamstrings:
            return .green
        case .Lats:
            return .orange
        case .Lowerback:
            return .purple
        case .MiddleBack:
            return .brown
        case .Neck:
            return .pink
        case .Quadriceps:
            return .red
        case .Shoulders:
            return .blue
        case .Traps:
            return .green
        case .Triceps:
            return .orange
        }
    }

    
    var image: String {
        switch self {
        case .all:
            return "AllMuscles"
        case .abdominals:
            return "AbsIcon"
        case .abductors:
            return "Abductor Machine"
        case .Adductors:
            return "Abductor Machine"
        case .Biceps:
            return "BicepIcon"
        case .Calves:
            return "CalvesIcon"
        case .Chest:
            return "ChestMuscleIcon"
        case .Forearms:
            return "forearms"
        case .Glutes:
            return "glutes"
        case .Hamstrings:
            return "Prone Curl Leg Machine"
        case .Lats:
            return "LatIcon"
        case .Lowerback:
            return "LowerBackIcon"
        case .MiddleBack:
            return "Lower back muscle"
        case .Neck:
            return "Upper back muscle"
        case .Quadriceps:
            return "quadriceps"
        case .Shoulders:
            return "Leverage Shoulder Press"
        case .Traps:
            return "Upper back muscle"
        case .Triceps:
            return "TricepIcon"
        }
    }
}


