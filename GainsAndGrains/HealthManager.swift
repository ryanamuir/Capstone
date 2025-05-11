import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        var readTypes = Set<HKQuantityType>()
        
        // Safely unwrap each type
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(stepCount)
        }
        if let energyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(energyBurned)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            readTypes.insert(heartRate)
        }
        
        guard !readTypes.isEmpty else { return }
            
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                } else {
                    print("HealthKit authorization succeeded: \(success)")
                }
            }
        }
    }
