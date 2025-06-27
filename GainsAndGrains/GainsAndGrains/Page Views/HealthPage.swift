//
//  HealthPage.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 18/05/2025.
//

import SwiftUI


struct HealthPage: View {
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var manager: HealthManager
    @EnvironmentObject private var tracker: MealTracker
    @EnvironmentObject private var tabManager: TabSelectionManager

    /// 1. Sort and turn your `[String: MetricData]` dictionary into an array
    private var sortedEntries: [(key: String, metric: MetricData)] {
        manager.metrics
            .sorted { $0.value.consumed < $1.value.consumed }
            .map { (key: $0.key, metric: $0.value) }
    }
    
    //Display the last workout completed by the user
    private var lastWorkout: WorkoutItem? {
        authState.workouts?
            .sorted { $0.time > $1.time }
            .first
    }
    
    //CARDWIDTH
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing: CGFloat = 16 * 3 // Padding + HStack spacing
        return (screenWidth - totalSpacing) / 2
    }
    
    // Builder for the lastworkout card
    @ViewBuilder
    private var lastWorkoutCard: some View {
        if let last = lastWorkout {
                PopularCard(item: .constant(last)) // Note: requires .constant here
                    .frame(width:cardWidth)
        }
    }

    /// 2. Build the left-hand summary list
    private var summaryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sortedEntries, id: \.key) { entry in
               
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 10) {
                        Text(entry.key)
                            .font(.callout).bold()
                        Image(systemName: entry.metric.icon)
                            .foregroundStyle(entry.metric.colour)
                    }
                    
                    Text("\(entry.metric.consumed)/\(entry.metric.goal)")
                        .bold()
                        .foregroundColor(entry.metric.colour)
                        .font(.title3)
                }
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .center)
    }

    /// 3. Build the concentric rings view
    private var ringsView: some View {
        // Map each entry into the ProgressCircle you already have
        let circles = sortedEntries.map { entry in
            ProgressCircle(
                consumed: entry.metric.consumed,
                colour: entry.metric.colour,
                goal: entry.metric.goal
            )
        }
        return ConcentricRings(circles: circles)
    }

    
    
    
    var body: some View {
            Group{
                    ScrollView {
                        VStack(alignment:.leading) {
                            // Rings + Summary
                            HStack {
                                Spacer()
                                summaryList
                                Spacer()
                                ringsView
                                Spacer()
                            }
                            .frame(minHeight: 230)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.2))
                            )
                            
                            Spacer(minLength: 15)
                            
                           
                            
                            // Cards
                            HStack {
                                StepCard(title: "Step Count", value: manager.today_steps?.1 ?? 0, goal: 10000, lastUpdated: manager.today_steps?.0 ?? Date(), unitColor: .purple)
                                    .frame(width: cardWidth, height: 250)
                                StepCard(title: "HeartRate", value: manager.lastBPM?.1 ?? 0, lastUpdated: manager.lastBPM?.0 ?? Date(), unitColor: .pink)
                                    .frame(width: cardWidth, height: 250)
                            }
                            
                            Spacer(minLength: 20)
                            
                            HStack {
                                StepCard(title: "Calories Consumed", value: Int(tracker.dailyTotal(for: Date())), goal: tracker.dailyCalTot, lastUpdated: Date(), unitColor: .orange)
                                
                                lastWorkoutCard
                            }
                            // Last workout
                            
                            
                            Spacer(minLength: 40)
                            
                            // Heart rate chart
                            HeartRateChartView()
                            
                            Spacer()
                        }
                        .padding(.top)
                        .padding(.horizontal)
                        
                    }
            }
            .onAppear{
                Task{
                    await authState.fetchWorkouts()
                }
            }
            
                        
        
    }

}


/// Stacks an array of ProgressCircle so each one gets 20pt more padding than the last.
struct ConcentricRings: View {
    let circles: [ProgressCircle]

    var body: some View {
        ZStack {
            ForEach(circles.indices, id: \.self) { idx in
                circles[idx]
                    .padding(CGFloat(22 * idx))
            }
        }
    }
}


struct StepCard: View {
    
    let title: String
    var value: Int
    var goal: Int?
    var lastUpdated: Date
    let unitColor: Color
    
    @State private var animatedProgress: Double = 0.0

    private var progress: Double? {
        if let goal = goal {
            return min(Double(value) / Double(goal), 1.0)
        }
        return nil
    }
    
    private var progressColor: Color {
        guard let progress = progress else {
            return .gray
        }
        if progress < 0.5 {
            return .green
        } else if progress < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    private var updateText: String {
        switch title {
        case "Step Count":
            if value == 0 {
                return "No steps have been recorded as of \(formattedDate)"
            } else {
                return "Last updated on \(formattedDate)"
            }
        case "Heart Rate":
            if value == 0 {
                return "There has been no update to HealthStore as of \(formattedDate)"
            } else {
                return "Last updated on \(formattedDate)"
            }
        default:
            return "Last updated on \(formattedDate)"
        }
    }
    
    private var iconName: String {
        switch title {
        case "Step Count":
            return "figure.walk.motion"
        case "HeartRate":
            return "heart.fill"
        case "Calories Consumed":
            return "fork.knife"
        default:
            return "questionmark"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title Row
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(unitColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }

            // Value Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Recorded")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                Text("\(value)")
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundColor(unitColor)
            }

            // Progress Bar
            if progress != nil {
                ProgressView(value: animatedProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 10)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(5)
            }

            Spacer()

            // Last Updated Text
            Text(updateText)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .onAppear {
            if let progress = progress {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
        }
    }
}


