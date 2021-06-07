/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model used to describe a health data value.
*/

import Foundation

/// A representation of health data to use for `HealthDataTypeTableViewController`.
struct HealthDataTypeValue {
    let startDate: Date
    let endDate: Date
    var value: Double
}


enum DataInterval {
    case day
    case week
    case month

    func label() -> String {
        switch self {
        case .day:
            return "Daily"
        case .week:
            return "Weekly"
        case .month:
            return "Monthly"
        }
    }

    func dateInterval() -> DateComponents {
        switch self {
        case .day:
            return DateComponents(day: 1)
        case .week:
            return DateComponents(weekOfYear: 1)
        case .month:
            return DateComponents(month: 1)
        }
    }
}
