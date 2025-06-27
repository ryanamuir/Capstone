//
//  MacroProgress.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 27/05/2025.
//

//
//  ProgressCircles.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 18/05/2025.
//

import SwiftUI

/// 1) A Shape that draws a variable-length semicircle (0…180°)
struct ProgressSemiCircle: Shape {
  /// 0…1, fraction of the half-circle
  var progress: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.maxY)
    let radius = rect.width / 2

    let start = Angle.degrees(180)
    // sweep out 180° × progress 180 is the left most and 0 the rightmost
    let end   = Angle.degrees(180 + 180 * min(progress, 1))

    path.addArc(
      center: center,
      radius: radius,
      startAngle: start,
      endAngle: end,
      clockwise: false
    )
    return path
  }
}

/// 2) A View that uses the Shape for both background & foreground,
///    and forces a 2:1 (width:height) aspect so height == width/2.
struct MacroTracker: View {
  var consumed: Int
  var goal: Int
  var colour: Color
  @State private var animatedfraction:Double = 0
  /// 0…1 of the half-circle


    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1)
      }

      var body: some View {
        ZStack {
          // background
          ProgressSemiCircle(progress: 1)
            .stroke(colour.opacity(0.15),
                    style: .init(lineWidth: 15, lineCap: .round))

          // foreground, driven by `fraction`
          ProgressSemiCircle(progress: fraction)
            .stroke(colour,
                    style: .init(lineWidth: 15, lineCap: .round))
            .shadow(color: colour.opacity(0.8), radius: 4)
            // → interpolate whenever `fraction` changes:
            .animation(.easeInOut(duration: 2), value: fraction)
        }
        
        .aspectRatio(2, contentMode: .fit)
      }
        
}


struct MacroTracker_Previews: PreviewProvider {
    static var previews: some View {
        // Animate from 0 to 1200 of a 2000 kcal goal
        MacroTracker(consumed:1000,goal:2000, colour: Color.red)
            .frame(width: 200, height: 200)
    }
}




