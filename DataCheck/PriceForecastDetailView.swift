//
//  PriceForecastDetailView.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import SwiftUI

struct ContractPeriod {
    let startDate: Date
    let endDate: Date
    let monthlyPrice: Double
    let description: String
}

struct ContractSummary {
    let totalCost: Double
    let averageMonthlyCost: Double
    let totalMonths: Int
    let periods: [ContractPeriod]
}

struct PriceForecastDetailView: View {
    let priceForecast: [String]
    let contractStartDate: String
    let contractEndDate: String
    @Environment(\.dismiss) private var dismiss
    
    private var contractSummary: ContractSummary {
        calculateContractSummary()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Summary Cards
                HStack(spacing: 16) {
                    summaryCard(
                        title: NSLocalizedString("total_contract_cost", comment: ""),
                        value: String(format: "€%.2f", contractSummary.totalCost),
                        icon: "eurosign.circle.fill",
                        color: .blue
                    )
                    
                    summaryCard(
                        title: NSLocalizedString("average_monthly_cost", comment: ""),
                        value: String(format: "€%.2f", contractSummary.averageMonthlyCost),
                        icon: "calendar.circle.fill",
                        color: .green
                    )
                }
                
                // Contract Duration
                InfoCard(title: NSLocalizedString("contract_duration", comment: "")) {
                    VStack(spacing: 12) {
                        InfoRow(
                            label: NSLocalizedString("total_months", comment: ""),
                            value: "\(contractSummary.totalMonths) \(NSLocalizedString("months", comment: ""))"
                        )
                        
                        Divider()
                        
                        InfoRow(
                            label: NSLocalizedString("contract_period", comment: ""),
                            value: "\(formatDate(contractStartDate)) - \(formatDate(contractEndDate))"
                        )
                    }
                }
                
                // Enhanced Price Breakdown
                InfoCard(title: NSLocalizedString("price_breakdown", comment: "")) {
                    VStack(spacing: 20) {
                        ForEach(Array(contractSummary.periods.enumerated()), id: \.offset) { index, period in
                            enhancedPriceBreakdownRow(period: period, index: index, isFirst: index == 0)
                            
                            if index < contractSummary.periods.count - 1 {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 4, height: 4)
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 1)
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 4, height: 4)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("price_forecast_details", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func enhancedPriceBreakdownRow(period: ContractPeriod, index: Int, isFirst: Bool) -> some View {
        let monthsInPeriod = calculateMonthsBetween(start: period.startDate, end: period.endDate)
        let totalForPeriod = period.monthlyPrice * Double(monthsInPeriod)
        let accentColor = isFirst ? Color.green : Color.blue
        
        return HStack(spacing: 16) {
            // Timeline indicator with enhanced design
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                    
                    if isFirst {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                if isFirst {
                    Text(NSLocalizedString("current", comment: ""))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                }
            }
            
            // Content with enhanced styling
            VStack(alignment: .leading, spacing: 12) {
                // Header with period info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(period.description)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Price badge
                        HStack(spacing: 4) {
                            Text(String(format: "€%.2f", period.monthlyPrice))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(accentColor)
                            
                            Text("/mo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Text("\(formatDate(period.startDate)) - \(formatDate(period.endDate))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Calculation breakdown with visual elements
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor)
                            
                            Text("\(monthsInPeriod) \(NSLocalizedString("months", comment: ""))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Image(systemName: "multiply")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "eurosign.circle")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor)
                            
                            Text(String(format: "€%.2f", period.monthlyPrice))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "equal")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "€%.2f", totalForPeriod))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    
                    // Progress bar showing relative cost
                    if contractSummary.totalCost > 0 {
                        let percentage = totalForPeriod / contractSummary.totalCost
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(String(format: "%.1f", percentage * 100))% of total cost")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(accentColor)
                                        .frame(width: geometry.size.width * percentage, height: 4)
                                        .animation(.easeInOut(duration: 0.5), value: percentage)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    
    private func calculateContractSummary() -> ContractSummary {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Fallback date formatter for simpler format
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = dateFormatter.date(from: contractStartDate) ?? simpleDateFormatter.date(from: contractStartDate),
              let endDate = dateFormatter.date(from: contractEndDate) ?? simpleDateFormatter.date(from: contractEndDate) else {
            return ContractSummary(totalCost: 0, averageMonthlyCost: 0, totalMonths: 0, periods: [])
        }
        
        var periods: [ContractPeriod] = []
        var currentDate = startDate
        
        for (index, forecast) in priceForecast.enumerated() {
            let parsedForecast = parsePriceForecast(forecast)
            let price = extractPrice(from: parsedForecast.price)
            
            var periodEndDate: Date
            
            if index < priceForecast.count - 1 {
                // Get the start date of the next period
                let nextForecast = priceForecast[index + 1]
                let nextParsed = parsePriceForecast(nextForecast)
                periodEndDate = extractDateFromPeriod(nextParsed.period) ?? endDate
            } else {
                // Last period goes until contract end
                periodEndDate = endDate
            }
            
            let period = ContractPeriod(
                startDate: currentDate,
                endDate: periodEndDate,
                monthlyPrice: price,
                description: parsedForecast.period
            )
            
            periods.append(period)
            currentDate = periodEndDate
        }
        
        // Calculate totals
        let totalMonths = calculateMonthsBetween(start: startDate, end: endDate)
        var totalCost: Double = 0
        
        for period in periods {
            let monthsInPeriod = calculateMonthsBetween(start: period.startDate, end: period.endDate)
            totalCost += period.monthlyPrice * Double(monthsInPeriod)
        }
        
        let averageMonthlyCost = totalMonths > 0 ? totalCost / Double(totalMonths) : 0
        
        return ContractSummary(
            totalCost: totalCost,
            averageMonthlyCost: averageMonthlyCost,
            totalMonths: totalMonths,
            periods: periods
        )
    }
    
    private func parsePriceForecast(_ forecast: String) -> (period: String, price: String) {
        if forecast.contains("volgende factuur:") || forecast.contains("next bill:") {
            let components = forecast.components(separatedBy: ":")
            if components.count >= 2 {
                let period = NSLocalizedString("next_bill", comment: "")
                let price = components[1].trimmingCharacters(in: .whitespaces)
                return (period, price)
            }
        } else if forecast.contains("vanaf") || forecast.contains("from") {
            let components = forecast.components(separatedBy: ":")
            if components.count >= 2 {
                let dateString = components[0].replacingOccurrences(of: "vanaf", with: "").replacingOccurrences(of: "from", with: "").trimmingCharacters(in: .whitespaces)
                let period = "\(NSLocalizedString("from", comment: "")) \(dateString)"
                let price = components[1].trimmingCharacters(in: .whitespaces)
                return (period, price)
            }
        }
        
        let components = forecast.components(separatedBy: ":")
        if components.count >= 2 {
            return (components[0].trimmingCharacters(in: .whitespaces), components[1].trimmingCharacters(in: .whitespaces))
        }
        
        return (forecast, "")
    }
    
    private func extractPrice(from priceString: String) -> Double {
        let cleanedString = priceString
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        
        return Double(cleanedString) ?? 0.0
    }
    
    private func extractDateFromPeriod(_ period: String) -> Date? {
        // Extract date from strings like "From 23-11" or "Vanaf 23-09-2026"
        let dateFormatter = DateFormatter()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Try different date formats
        let patterns = [
            "dd-MM-yyyy",
            "dd-MM",
            "yyyy-MM-dd"
        ]
        
        for pattern in patterns {
            dateFormatter.dateFormat = pattern
            
            // Extract potential date string from period
            let components = period.components(separatedBy: " ")
            for component in components {
                if let date = dateFormatter.date(from: component) {
                    // If it's just day-month, assume current year or next year based on context
                    if pattern == "dd-MM" {
                        let month = calendar.component(.month, from: date)
                        let day = calendar.component(.day, from: date)
                        
                        // Create date with current year first
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = month
                        dateComponents.day = day
                        
                        if let dateWithCurrentYear = calendar.date(from: dateComponents) {
                            // If the date is in the past, use next year
                            if dateWithCurrentYear < Date() {
                                dateComponents.year = currentYear + 1
                                return calendar.date(from: dateComponents)
                            }
                            return dateWithCurrentYear
                        }
                    }
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func calculateMonthsBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: start, to: end)
        return max(components.month ?? 0, 1) // At least 1 month
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
        } else {
            // Try alternative format
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "dd MMM yyyy"
                return formatter.string(from: date)
            }
        }
        
        return dateString
    }
}

#Preview {
    PriceForecastDetailView(
        priceForecast: [
            "volgende factuur: € 5,69",
            "vanaf 23-11: € 5,00",
            "vanaf 23-09-2026: € 10,00"
        ],
        contractStartDate: "2025-09-23T00:00:00+0200",
        contractEndDate: "2027-09-23T00:00:00+0200"
    )
}
