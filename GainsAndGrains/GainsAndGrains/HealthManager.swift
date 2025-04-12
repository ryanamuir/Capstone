import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    func requestAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            let readTypes: Set = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!
            ]
            
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                } else {
                    print("HealthKit authorization succeeded: \(success)")
                }
            }
        }
    }
}
