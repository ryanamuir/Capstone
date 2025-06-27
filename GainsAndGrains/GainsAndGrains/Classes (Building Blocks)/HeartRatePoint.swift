import SwiftUI
import Charts

// 1) Your animatable line‐shape, unchanged
import SwiftUI

struct HeartLine: Shape {
    let points: [HeartRatePoint]
    let yDomain: ClosedRange<Double> // ⬅️ Use fixed domain (same as .chartYScale)
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let ts = points.map(\.date.timeIntervalSinceReferenceDate)
        let vs = points.map(\.bpm)

        guard let t0 = ts.min(), let t1 = ts.max(), t0 != t1 else {
            return Path()
        }

        // 🔥 FIX: Use fixed chart-wide domain
        let v0 = yDomain.lowerBound
        let v1 = yDomain.upperBound

        func x(_ t: TimeInterval) -> CGFloat {
            CGFloat((t - t0) / (t1 - t0)) * rect.width
        }

        func y(_ v: Double) -> CGFloat {
            (1 - CGFloat((v - v0) / (v1 - v0))) * rect.height
        }

        var p = Path()
        p.move(to: CGPoint(x: x(ts[0]), y: y(vs[0])))
        for i in 1..<points.count {
            p.addLine(to: CGPoint(x: x(ts[i]), y: y(vs[i])))
        }

        return p.trimmedPath(from: 0, to: progress)
    }
}


// 2) Your data model
struct HeartRatePoint: Identifiable {
  let id = UUID()
  let date: Date
  let bpm: Double
}

// 3) The chart view that overlays HeartLine
struct HeartRateChartView: View {
    @EnvironmentObject private var manager: HealthManager
    @State private var animProgress: CGFloat = 0

    private var data: [HeartRatePoint] {
        manager.hourlyData
            .map { HeartRatePoint(date: $0.0, bpm: $0.1) }
            .sorted { $0.date < $1.date }
    }

    var topBpm: Double {
        ceil((data.map(\.bpm).max() ?? 100) / 10) * 10 + 5
    }

    private let pointWidth: CGFloat = 60
    private let sweepDuration: TimeInterval = 2

    var body: some View {
        VStack(alignment: .leading) {
            //TITLE OF GRAPH
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Heart Rate Trends")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Last 24 Hours (BPM)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.bottom)

            ScrollView(.horizontal, showsIndicators: false) {
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("BPM", point.bpm)
                    )
                    .opacity(0) // hidden base line just for axes

                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("BPM", point.bpm)
                    )
                    .foregroundStyle(.red)
                    .annotation(position: .automatic) {
                        Text(String(format: "%.0f", point.bpm))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 10)) { _ in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: data.count)) { _ in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .abbreviated)))
                            .font(.caption)
                    }
                }
                .chartXAxisLabel("Hour of Day", position: .bottom)
                .chartYAxisLabel("BPM", position: .leading)
                .chartYScale(domain: 0...topBpm)
                .chartXScale(domain: (data.first?.date ?? Date()) ... (data.last?.date ?? Date()))
                .frame(width: CGFloat(data.count) * pointWidth, height: 200)
                //.padding(.top)
                //.padding(.bottom)
                .padding()
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        if let anchor = proxy.plotFrame {
                            Group {
                                let plotFrame = geo[anchor]
                                HeartLine(points: data, yDomain: 0...topBpm, progress: animProgress)
                                    .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: plotFrame.width, height: plotFrame.height)
                                    .offset(x: plotFrame.minX, y: plotFrame.minY)
                            }
                        } else {
                            Color.white
                        }
                    }
                }
                .onAppear {
                    animProgress = 0
                    withAnimation(.linear(duration: sweepDuration)) {
                        animProgress = 1
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .shadow(radius: 4)
    }
}


