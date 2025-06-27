//
//  Preprocessor.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 22/04/2025.
//

import Foundation
import CoreML

/// A singleton you can call from your SwiftUI view
class Preprocessor {
  static let shared = Preprocessor()
    
  let titles:        [String]
  let typeCats:      [String]
  let bodyPartCats:  [String]
  let equipCats:     [String]
  let levelCats:     [String]
  let ratingMean:    Double
  let ratingScale:   Double

  private init() {
    // 1) Load the JSON you bundled
      guard
            let url  = Bundle.main.url(forResource: "preproc", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let top  = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
            let cats = top["categories"] as? [String:[String]],
            let titles_       = cats["Title"],
            let typeCats_     = cats["Type"],
            let bodyPartCats_ = cats["BodyPart"],
            let equipCats_    = cats["Equipment"],
            let levelCats_    = cats["Level"],
            let mean  = top["rating_mean"]  as? Double,
            let scale = top["rating_scale"] as? Double
    
      else {
          fatalError("❌ Failed to load or parse preproc.json") }
      self.titles       = titles_
      self.typeCats     = typeCats_
      self.bodyPartCats = bodyPartCats_
      self.equipCats    = equipCats_
      self.levelCats    = levelCats_
      self.ratingMean   = mean
      self.ratingScale  = scale
          
            
  }

  /// Build your 1×37 MLMultiArray from raw inputs
    func makeInputArray(
      type: String,
      bodyPart: String,
      equipment: String,
      level: String,
      rating: Double
    ) throws -> MLMultiArray {
      let N_type  = typeCats.count
      let N_bp    = bodyPartCats.count
      let N_eq    = equipCats.count
      let N_lvl   = levelCats.count
      let featureCount = N_type + N_bp + N_eq + N_lvl + 1

      // 1) Allocate a 2-D array [1, featureCount]
      let arr = try MLMultiArray(
        shape: [1, NSNumber(value: featureCount)],
        dataType: .double
      )

      // 2) Zero-fill
      for j in 0..<featureCount {
        arr[[0, NSNumber(value: j)]] = 0
      }

      var offset = 0
      // 3) One-hot blocks—note the 2-D indexing [0, offset + i]
      if let i = typeCats.firstIndex(of: type) {
        arr[[0, NSNumber(value: offset + i)]] = 1
      }
      offset += N_type

      if let i = bodyPartCats.firstIndex(of: bodyPart) {
        arr[[0, NSNumber(value: offset + i)]] = 1
      }
      offset += N_bp

      if let i = equipCats.firstIndex(of: equipment) {
        arr[[0, NSNumber(value: offset + i)]] = 1
      }
      offset += N_eq

      if let i = levelCats.firstIndex(of: level) {
        arr[[0, NSNumber(value: offset + i)]] = 1
      }
      offset += N_lvl

      // 4) Standardize rating
      let scaled = (rating - ratingMean) / ratingScale
      arr[[0, NSNumber(value: offset)]] = NSNumber(value: Float32(scaled))

      return arr
    }

    
    

}

