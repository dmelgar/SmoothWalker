/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view controller that displays charts for mobility health data.
*/

import UIKit
import HealthKit

/// A representation of health data related to mobility.
class MobilityChartDataViewController: DataTypeCollectionViewController {

    let calendar: Calendar = .current
    var intervalType: DataInterval = .day
    var speedMode = false
    
    var mobilityContent: [String] = [
        HKQuantityTypeIdentifier.stepCount.rawValue,
        HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
    ]
    
    var queries: [HKAnchoredObjectQuery] = []
    
    // MARK: - View Life Cycle

    init(speedMode: Bool = false) {
        super.init()
        self.speedMode = speedMode
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if speedMode {
            data.append((HKQuantityTypeIdentifier.walkingSpeed.rawValue, [], .day))
            data.append((HKQuantityTypeIdentifier.walkingSpeed.rawValue, [], .week))
            data.append((HKQuantityTypeIdentifier.walkingSpeed.rawValue, [], .month))
        } else {
            data = mobilityContent.map { ($0, [], .day) }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Authorization
        if !queries.isEmpty { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: mobilityContent) { (success) in
            if success {
                self.setUpBackgroundObservers()
                self.loadData()
            }
        }
    }
    
    // MARK: - Data Functions
    
    func loadData() {
        performQuery {
            // Dispatch UI updates to the main thread.
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    func setUpBackgroundObservers() {
        data.compactMap { getSampleType(for: $0.dataTypeIdentifier) }.forEach { (sampleType) in
            createAnchoredObjectQuery(for: sampleType)
        }
    }
    
    func createAnchoredObjectQuery(for sampleType: HKSampleType) {
        // Customize query parameters
        let predicate = createLastWeekPredicate()
        let limit = HKObjectQueryNoLimit
        
        // Fetch anchor persisted in memory
        let anchor = HealthData.getAnchor(for: sampleType)
        
        // Create HKAnchoredObjecyQuery
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: predicate, anchor: anchor, limit: limit) {
            (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        // Create update handler for long-running background query
        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            // The results come back on an anonymous background queue.
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        HealthData.healthStore.execute(query)
        queries.append(query)
    }
    
    // MARK: Data Functions

    func performQuery(completion: @escaping () -> Void) {
        // Create a query for each data type.
        for (index, item) in data.enumerated() {

            let startDate = getStartDate(intervalType: item.intervalType)
            let dateInterval = item.intervalType.dateInterval()  

            // Set dates
            let endDate = Date()
            let predicate = createPredicate(startDate: startDate, endDate: endDate)

            // Process data.
            let statisticsOptions = getStatisticsOptions(for: item.dataTypeIdentifier)
            let initialResultsHandler: (HKStatisticsCollection) -> Void = { (statisticsCollection) in
                var values: [Double] = []
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                    let statisticsQuantity = getStatisticsQuantity(for: statistics, with: statisticsOptions)
                    if let unit = preferredUnit(for: item.dataTypeIdentifier),
                        let value = statisticsQuantity?.doubleValue(for: unit) {
                        values.append(value)
                    } else {
                        // Chart does not render any values if some values not present
                        values.append(0)
                    }
                }

                self.data[index].values = values

                completion()
            }

            // Fetch statistics.
            HealthData.fetchStatistics(with: HKQuantityTypeIdentifier(rawValue: item.dataTypeIdentifier),
                                       predicate: predicate,
                                       options: statisticsOptions,
                                       startDate: startDate,
                                       interval: dateInterval,
                                       completion: initialResultsHandler)
        }
    }
}
