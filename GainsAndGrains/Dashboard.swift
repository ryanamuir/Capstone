import SwiftUI
import CoreML

extension MLMultiArray {
    func topKIndices(_ k: Int) -> [Int] {
        let pairs: [(Int, Double)] = (0..<self.count).map { ($0, self[$0].doubleValue) }
        let sorted = pairs.sorted { $0.1 > $1.1 }
        return Array(sorted.prefix(k).map { $0.0 })
    }
}

struct DashboardView: View {
    @EnvironmentObject private var authState: AuthState
    
    
    @State var level: String = "Intermediate"
    @State var rating: Double = 8
    @State var model = try! Workouts(configuration: MLModelConfiguration())
    @State var pre   = Preprocessor.shared
    @State var bodyParts = ["Chest", "Quadriceps", "Shoulder", "Biceps"]
    @State var columns = [GridItem(.flexible())]
    @State private var recommendations: [String: [String]] = [:]

    var body: some View {
        Group {
            if let user = authState.currentuser {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(bodyParts, id: \.self) { part in
                                RecommendationCard(
                                    bodyPart: part,
                                    suggestions: recommendations[part] ?? []
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
                .onAppear {
                    if authState.currentuser == nil {
                            Task {
                                await authState.fetchUser()
                            }
                        }
                    computeRecommendations(for: user)
                }
                .navigationTitle("Your Workout Picks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            } else {
                ProgressView("Loading your dashboard...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
    }

    func computeRecommendations(for user: User) {
        var newRecs: [String: [String]] = [:]

        for part in bodyParts {
            do {
                let mlArr = try pre.makeInputArray(
                    type: user.fitnessGoal,
                    bodyPart: part,
                    equipment: user.equipmentAccess,
                    level: level,
                    rating: rating
                )
                let input = WorkoutsInput(dense_input: mlArr)
                let output = try model.prediction(input: input)
                let probs = output.Identity
                let top2 = probs.topKIndices(3)
                let suggestions = top2.map { pre.titles[$0] }

                newRecs[part] = suggestions
            } catch {
                newRecs[part] = ["—", "—", "—"]
            }
        }

        recommendations = newRecs
    }
}

struct RecommendationCard: View {
    let bodyPart: String
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing))
                .frame(width: 50, height: 5)
                .cornerRadius(2.5)

            Text(bodyPart)
                .font(.headline)
                .foregroundColor(.white)

            Divider().background(Color.gray)

            ForEach(0..<min(suggestions.count, 2), id: \.self) { i in
                Text(suggestions[i])
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.sRGB, white: 0.15, opacity: 1))
                .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}
