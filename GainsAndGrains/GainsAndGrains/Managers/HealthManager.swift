import HealthKit
import Foundation
import SwiftUI
import Combine

/// Model for your progress circle

extension Date {
    
    var isWeekend: Bool {
        let calendar = Calendar.current
        return calendar.isDateInWeekend(self)
    }

    
    /// Returns the start of the hour that contains this date.
    var flooredToHour: Date {
        Calendar.current
          .dateInterval(of: .hour, for: self)!
          .start
    }
    
    /// A Date exactly one week before now
    static var oneWeekAgo: Date {
        Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: Date()
        )!
    }
    
    static var Today = Calendar.current.startOfDay(for: Date())
    
    static var LastMin = Calendar.current.date(byAdding: .hour, value: -1, to: now)
    
    static var Last24hrs = Calendar.current.date(byAdding: .hour, value: -24, to: now)!.flooredToHour
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var weekDates: [Date] {
        guard let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return []
        }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var monthDates: [Date] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        return range.compactMap { day in
            var components = calendar.dateComponents([.year, .month], from: startOfMonth)
            components.day = day
            return calendar.date(from: components)
        }
    }

    
    var dayNumber: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self).uppercased()
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    
// end of Date Extensions
}

@MainActor
class HealthManager: ObservableObject {
    private let authState: AuthState
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var metrics: [String: MetricData] = [:]
    @Published var hourlyData: [(Date, Double)] = []
    @Published var lastBPM: (Date, Int)?
    @Published var today_steps : (Date,Int)?
    //@Published var
    
    
    init(authState: AuthState) {
        self.authState = authState
        // don’t start HK until we know who the user is:
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authState.$currentuser
            .compactMap { $0 }
            .first()
            .sink { [weak self] user in
                guard let self = self else { return }
                print("🔐 User ready—setting up HealthKit observers")
                self.requestAuthorization()
                self.startObserversAndFetches()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authorization
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let calorietype = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distancetype = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let heartrate = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        healthStore.requestAuthorization(toShare: [], read: [stepsType,calorietype,distancetype,heartrate]) { success, error in
            if let error = error {
                print("🔒 HealthKit auth error:", error.localizedDescription)
            }
        }
    }
    
    /// Group all of your observer registrations and initial fetches here
    private func startObserversAndFetches() {
        StepObserver()
        CaloriesObserver()
        DistanceObserver()
        HeartRateObserver()
        
        // Wrap calls that call main-actor methods
        Task { @MainActor in
            self.fetchWeeklySteps()
            self.fetchWeeklyCalories()
            self.fetchWeeklyDistance()
            self.FetchHeartRate()
            self.currentHR()
            self.currentStepsToday()
        }
    }
    
    // ... unchanged authorization and observer methods ...
    
    private func StepObserver() {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let query = HKObserverQuery(
            sampleType: stepsType,
            predicate: nil
        ) { [weak self] _, _, error in
            if let error = error {
                print("ObserverQuery error:", error.localizedDescription)
                return
            }
            Task { @MainActor in
                self?.currentStepsToday()
                self?.fetchWeeklySteps()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepsType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error:", error.localizedDescription)
            }
        }
    }
    
    private func CaloriesObserver() {
        guard let caltype = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let query = HKObserverQuery(
            sampleType: caltype,
            predicate: nil
        ) { [weak self] _, _, error in
            if let error = error {
                print("ObserverQuery error:", error.localizedDescription)
                return
            }
            Task { @MainActor in
                self?.fetchWeeklyCalories()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: caltype, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error:", error.localizedDescription)
            }
        }
    }
    
    private func DistanceObserver() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let query = HKObserverQuery(
            sampleType: distanceType,
            predicate: nil
        ) { [weak self] _, _, error in
            if let error = error {
                print("ObserverQuery error:", error.localizedDescription)
                return
            }
            Task { @MainActor in
                self?.fetchWeeklyDistance()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: distanceType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error:", error.localizedDescription)
            }
        }
    }
    
    private func HeartRateObserver() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(
            sampleType: heartRateType,
            predicate: nil
        ) { [weak self] _, _, error in
            if let error = error {
                print("ObserverQuery error:", error.localizedDescription)
                return
            }
            Task { @MainActor in
                self?.currentHR()
                self?.FetchHeartRate()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error:", error.localizedDescription)
            }
        }
    }
    
    
    // MARK: - Statistics Query
    func fetchWeeklySteps() {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: .oneWeekAgo, end: Date())
        let statsQuery = HKStatisticsQuery(
            quantityType: stepsType,
            quantitySamplePredicate: predicate
        ) { [weak self] _, result, error in
            guard let self = self, let sum = result?.sumQuantity(), error == nil else {
                print("HKStatisticsQuery error:", error?.localizedDescription ?? "unknown")
                return
            }
            
            let weeklySteps = sum.doubleValue(for: .count())
            print("\(weeklySteps)")
            let goal = 70000.0  // e.g. 10,000 steps/day
            
            DispatchQueue.main.async {
                self.metrics["Weekly Steps"] = MetricData(
                    icon: "figure.stair.stepper",
                    consumed:Int(weeklySteps),
                    colour: .exerciseGreen,
                    goal: Int(goal),
                    type:.steps
                )
            }
        }
        
        healthStore.execute(statsQuery)
    }
    
    func fetchWeeklyCalories(){
        let calories = HKQuantityType(.activeEnergyBurned)
        let pred = HKQuery.predicateForSamples(withStart: .oneWeekAgo, end: Date())
        let query = HKStatisticsQuery(quantityType: calories, quantitySamplePredicate: pred) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else{
                print("Error occured: \(error!.localizedDescription)")
                return
            }
            let weekly_cal = quantity.doubleValue(for: .kilocalorie())
            print("\(weekly_cal)")
            
            DispatchQueue.main.async {
                guard let user = self.authState.currentuser else {
                    print("⚠️ No current user; using fallback goal")
                    self.metrics["Weekly Calories"] = MetricData(
                        icon: "flame",
                        consumed: Int(weekly_cal),
                        colour: .red,
                        goal:500 * 7,
                        type:.calories
                    )
                    return
                }
                print("✅ Using user targetCalBurned: \(user.targetCalBurned)")
                self.metrics["Weekly Calories"] = MetricData(
                    icon: "flame",
                    consumed: Int(weekly_cal),
                    colour: .moveRed,
                    goal: user.targetCalBurned * 7,
                    type: .calories
                )
            }
            
            
            
        }
        healthStore.execute(query)
        
    }
    
    func fetchWeeklyDistance(){
        let distance = HKQuantityType(.distanceWalkingRunning)
        let pred = HKQuery.predicateForSamples(withStart: .oneWeekAgo, end: Date())
        let query = HKStatisticsQuery(quantityType: distance, quantitySamplePredicate: pred) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else{
                print("Error occured: \(error!.localizedDescription)")
                return
            }
            let weekly_distance = quantity.doubleValue(for: .meter())/1000
            print("\(weekly_distance)")
            
            DispatchQueue.main.async {
                self.metrics["Weekly Distance"] = MetricData(
                    icon: "figure.run",
                    consumed:Int(weekly_distance),
                    colour:.standBlue,
                    goal: 35,
                    type:.distance
                )
            }
        }
        healthStore.execute(query)
        
    }
    
    func FetchHeartRate(){
        
        let intervals = DateComponents(hour:1)
        let heartrate = HKQuantityType(.heartRate)
        let pred = HKQuery.predicateForSamples(withStart:.Last24hrs, end: Date())
        let query = HKStatisticsCollectionQuery(quantityType: heartrate, quantitySamplePredicate: pred, options:.discreteAverage, anchorDate: .Last24hrs, intervalComponents: intervals)
        query.initialResultsHandler = { _, results, error in
            
            //ensures data was actuallt retrieved
            if let statsCollection = results {
                //loops through the data
                statsCollection.enumerateStatistics(from:.Last24hrs,to: Date()) { stats, _ in
                    
                    // inside FetchHeartRate()
                    DispatchQueue.main.async {
                        self.hourlyData = [] // ✅ clear before adding fresh data
                    }
                    statsCollection.enumerateStatistics(from:.Last24hrs,to: Date()) { stats, _ in
                        DispatchQueue.main.async {
                            if let qty = stats.averageQuantity() {
                                let bpm = qty.doubleValue(for:.count().unitDivided(by:.minute()))
                                self.hourlyData.append((stats.startDate, bpm))
                            } else {
                                self.hourlyData.append((stats.startDate, 0))
                            }
                        }
                    }
                    
                }
            }
            
        }
        healthStore.execute(query)
    }
    
    func currentHR() {
        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: .LastMin, end: Date())
        
        //SORTING DESCRIPTOR
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            //CONVERTS THE SAMPLE QUERY AS A HKQUANTITYSAMPLE
            guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                print("Error occurred: \(error?.localizedDescription ?? "Maybe no data available")")
                return
            }
            
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let date = sample.startDate
            
            print("Last BPM is: \(bpm) at \(date)")
            
            DispatchQueue.main.async {
                self.lastBPM = (date, Int(bpm))
            }
        }
        
        healthStore.execute(query)
    }
    
    
    func currentStepsToday() {
        let todaysteps = HKQuantityType(.stepCount)
        let pred = HKQuery.predicateForSamples(withStart: .Today, end: Date())
        
        let query = HKStatisticsQuery(quantityType: todaysteps, quantitySamplePredicate: pred, options: .cumulativeSum) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("Error occurred: \(error?.localizedDescription ?? "Maybe no steps today")")
                return
            }
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let localPredicate = HKQuery.predicateForSamples(withStart: .Today, end: Date()) // 💡 This line fixes the concurrency warning
            let sample_query = HKSampleQuery(sampleType: todaysteps, predicate: localPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                    print("Error occurred: \(error?.localizedDescription ?? "Maybe no step data available")")
                    return
                }
                
                let date = sample.startDate
                let steps_today = quantity.doubleValue(for: .count())
                DispatchQueue.main.async {
                    self.today_steps = (date,Int(steps_today))
                   
                }
            }
            self.healthStore.execute(sample_query)
        }
        healthStore.execute(query)
    }

}

enum MetricType {
    case distance, steps, calories
}

struct MetricData {
    let icon: String
    let consumed: Int
    let colour: Color
    let goal: Int
    let type: MetricType
}
    

extension Color {
    static let moveRed = Color(red: 1.0, green: 0.2, blue: 0.4)
    static let exerciseGreen = Color(red: 0.1, green: 1.0, blue: 0.3)
    static let standBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
}
    





