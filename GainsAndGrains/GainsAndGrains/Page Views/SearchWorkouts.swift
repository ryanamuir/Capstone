//
//  SearchWorkouts.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 06/06/2025.
//

import SwiftUI

import SwiftUI
import AVFoundation
import AVKit

struct SearchWorkouts: View {
    @State private var searchword: String = ""
    @EnvironmentObject private var authState: AuthState

    var body: some View {
        List {
                if !authState.workout_description.isEmpty {
                    Section("Results Matching Your Search") {
                        ForEach(authState.workout_description, id: \.self) { workout in
                            NavigationLink(value: workout) {
                                Text(workout.Title)
                            }
                        }
                    }
                }
                
        }
        .navigationDestination(for: WorkoutDescription.self) { workoutDescription in
            SearchResultsCard(workout: workoutDescription)
        }
        .searchable(text: $searchword, prompt: "Find Exercise Information")
        .onChange(of: searchword) {
            Task {
                await authState.fetchExerciseInfo(matching: searchword.lowercased())
            }
        }
    }
}



struct SearchResultsCard: View {
    @EnvironmentObject private var authState: AuthState
    @State var workout: WorkoutDescription
    @State private var player: AVPlayer? = nil

    // Helper property for local video URL
    private var url: URL? {
        switch workout.Title.lowercased() {
        case "bench press":
            return Bundle.main.url(forResource: "bench press_61", withExtension: "mp4")
            
        case "triceps pushdown":
            return Bundle.main.url(forResource: "tricep pushdown_11", withExtension: "mp4")
            
        case "lat pull-down":
            return Bundle.main.url(forResource: "lat pulldown_29", withExtension: "mp4")
        default:
            return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Video Player (optional binding)
                if url != nil {
                    VideoPlayer(player: player)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 4)
                } else {
                    Text("Video not available")
                        .foregroundColor(.red)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                // Workout Name
                Text(workout.Title)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Description
                Text(workout.Desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(alignment: .center)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .onAppear {
            if let url = url {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
