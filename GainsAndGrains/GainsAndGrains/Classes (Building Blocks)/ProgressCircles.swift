//
//  ProgressCircles.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 18/05/2025.
//

import SwiftUI

struct ProgressCircle: View {
    var consumed: Int
    var colour: Color
    var goal: Int

    /// Raw fraction, e.g. 1.5 for 150%
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(consumed) / Double(goal)
    }

    /// Primary ring goes 0…1
    private var primary: Double {
        min(progress, 1.0)
    }

    /// Overflow fraction beyond 1.0, e.g. 0.5 if you’re at 150%
    private var overflow: Double {
        max(progress - 1.0, 0.0)
    }

    @State private var animatedPrimary: Double = 0
    @State private var animatedOverflow: Double = 0

    var body: some View {
        ZStack {
            // background track
            Circle()
                .stroke(colour.opacity(0.15), lineWidth: 20)
            

            // primary ring
            Circle()
                .trim(from: 0, to: animatedPrimary)
                .stroke(colour, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: colour.opacity(0.8), radius: 4, x: 0, y: 0) // glow

            // overflow ring
            if overflow > 0 {
                Circle()
                    .trim(from: 0, to: animatedOverflow)
                    .stroke(colour.opacity(0.7), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: colour.opacity(0.5), radius: 2, x: 0, y: 0)
            }
        }
        .padding(10)
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                animatedPrimary  = primary
                animatedOverflow = overflow
            }
        }

    }
}


struct CalorieProgressView_Previews: PreviewProvider {
    static var previews: some View {
        // Animate from 0 to 1200 of a 2000 kcal goal
        ProgressCircle(consumed:100,colour: Color.red,goal:2000)
            .frame(width: 200, height: 200)
    }
}




