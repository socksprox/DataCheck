//
//  UsageAnalyzer.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import Foundation

struct DailyUsage {
    let date: Date
    let dataUsageMB: Double
    let isWeekend: Bool
}

struct UsageInsights {
    let dailyUsages: [DailyUsage]
    let averageDailyUsage: Double
    let weekdayAverage: Double
    let weekendAverage: Double
    let highestUsageDay: DailyUsage?
    let lowestUsageDay: DailyUsage?
    let trend: UsageTrend
    let outliers: [DailyUsage]
    let recentDaysCount: Int
}

enum UsageTrend {
    case increasing
    case decreasing
    case stable
}

class UsageAnalyzer {
    static func analyzeUsage(from cdrData: [CdrRecord]) -> UsageInsights? {
        // Filter for data usage records only
        let dataRecords = cdrData.filter { $0.cdrType.lowercased().contains("data") }
        
        guard !dataRecords.isEmpty else { return nil }
        
        // Group by date and calculate daily usage
        let dailyUsages = calculateDailyUsages(from: dataRecords)
        
        guard !dailyUsages.isEmpty else { return nil }
        
        let averageDailyUsage = dailyUsages.map { $0.dataUsageMB }.reduce(0, +) / Double(dailyUsages.count)
        
        // Calculate weekday vs weekend averages
        let weekdayUsages = dailyUsages.filter { !$0.isWeekend }
        let weekendUsages = dailyUsages.filter { $0.isWeekend }
        
        let weekdayAverage = weekdayUsages.isEmpty ? 0 : weekdayUsages.map { $0.dataUsageMB }.reduce(0, +) / Double(weekdayUsages.count)
        let weekendAverage = weekendUsages.isEmpty ? 0 : weekendUsages.map { $0.dataUsageMB }.reduce(0, +) / Double(weekendUsages.count)
        
        // Find highest and lowest usage days
        let highestUsageDay = dailyUsages.max { $0.dataUsageMB < $1.dataUsageMB }
        let lowestUsageDay = dailyUsages.min { $0.dataUsageMB < $1.dataUsageMB }
        
        // Calculate trend
        let trend = calculateTrend(from: dailyUsages)
        
        // Detect outliers
        let outliers = detectOutliers(from: dailyUsages)
        
        return UsageInsights(
            dailyUsages: dailyUsages,
            averageDailyUsage: averageDailyUsage,
            weekdayAverage: weekdayAverage,
            weekendAverage: weekendAverage,
            highestUsageDay: highestUsageDay,
            lowestUsageDay: lowestUsageDay,
            trend: trend,
            outliers: outliers,
            recentDaysCount: dailyUsages.count
        )
    }
    
    private static func calculateDailyUsages(from records: [CdrRecord]) -> [DailyUsage] {
        let dateFormatter = DateFormatter()
        // Handle both formats: with and without milliseconds
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Group records by date
        var dailyUsageMap: [String: Double] = [:]
        
        for record in records {
            guard let date = dateFormatter.date(from: record.startDate) else { continue }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"
            let dayKey = dayFormatter.string(from: date)
            
            // Convert duration to MB (assuming duration represents data usage)
            // This is a simplified conversion - you might need to adjust based on actual API response
            let dataUsageMB = parseDataUsage(from: record.duration)
            
            dailyUsageMap[dayKey, default: 0] += dataUsageMB
        }
        
        // Convert to DailyUsage objects
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        let calendar = Calendar.current
        
        return dailyUsageMap.compactMap { (dayKey, usage) in
            guard let date = dayFormatter.date(from: dayKey) else { return nil }
            
            let isWeekend = calendar.isDateInWeekend(date)
            
            return DailyUsage(
                date: date,
                dataUsageMB: usage,
                isWeekend: isWeekend
            )
        }.sorted { $0.date < $1.date }
    }
    
    private static func parseDataUsage(from duration: String) -> Double {
        // Parse data usage from duration string
        // Handle European number format with comma as decimal separator
        
        // Look for patterns like "1,5 GB", "500,25 MB", etc. (European format)
        let patterns = [
            ("([0-9,]+)\\s*GB", 1000.0), // GB to MB
            ("([0-9,]+)\\s*MB", 1.0),    // MB
            ("([0-9,]+)\\s*KB", 0.001)   // KB to MB
        ]
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration)),
               let range = Range(match.range(at: 1), in: duration) {
                let numberString = String(duration[range]).replacingOccurrences(of: ",", with: ".")
                if let value = Double(numberString) {
                    return value * multiplier
                }
            }
        }
        
        // Fallback: try to extract any number with comma and assume it's MB
        if let regex = try? NSRegularExpression(pattern: "([0-9,]+)", options: []),
           let match = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration)),
           let range = Range(match.range(at: 1), in: duration) {
            let numberString = String(duration[range]).replacingOccurrences(of: ",", with: ".")
            if let value = Double(numberString) {
                return value // Assume MB
            }
        }
        
        return 0
    }
    
    private static func calculateTrend(from dailyUsages: [DailyUsage]) -> UsageTrend {
        guard dailyUsages.count >= 3 else { return .stable }
        
        // Use linear regression to determine trend
        let n = Double(dailyUsages.count)
        let xValues = Array(0..<dailyUsages.count).map { Double($0) }
        let yValues = dailyUsages.map { $0.dataUsageMB }
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        
        // Determine trend based on slope
        if slope > 5 { // Increasing by more than 5MB per day on average
            return .increasing
        } else if slope < -5 { // Decreasing by more than 5MB per day on average
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private static func detectOutliers(from dailyUsages: [DailyUsage]) -> [DailyUsage] {
        guard dailyUsages.count >= 3 else { return [] }
        
        let usageValues = dailyUsages.map { $0.dataUsageMB }
        let mean = usageValues.reduce(0, +) / Double(usageValues.count)
        
        // Calculate standard deviation
        let variance = usageValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(usageValues.count)
        let standardDeviation = sqrt(variance)
        
        // Consider values more than 2 standard deviations away as outliers
        let threshold = 2.0 * standardDeviation
        
        return dailyUsages.filter { abs($0.dataUsageMB - mean) > threshold }
    }
}

// Helper extension for date formatting
extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}
