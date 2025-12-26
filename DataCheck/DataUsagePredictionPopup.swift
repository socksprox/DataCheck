//
//  DataUsagePredictionPopup.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import SwiftUI

struct DataUsagePredictionPopup: View {
    let dataUsed: Double // in MB
    let dataTotal: Double // in MB
    let daysRemaining: Int
    let totalDaysInPeriod: Int
    let subscriptionGroupId: String
    @Binding var isPresented: Bool
    
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var usageInsights: UsageInsights?
    @State private var isAnalyzing = true
    
    // Computed properties for calculations
    private var dataUsedGB: Double {
        dataUsed / 1000
    }
    
    private var dataTotalGB: Double {
        dataTotal / 1000
    }
    
    private var daysElapsed: Int {
        totalDaysInPeriod - daysRemaining
    }
    
    private var dailyAverageGB: Double {
        guard daysElapsed > 0 else { return 0 }
        return dataUsedGB / Double(daysElapsed)
    }
    
    private var predictedTotalGB: Double {
        dailyAverageGB * Double(totalDaysInPeriod)
    }
    
    private var dailyBudgetGB: Double {
        guard daysRemaining > 0 else { return 0 }
        let remainingDataGB = dataTotalGB - dataUsedGB
        return max(0, remainingDataGB / Double(daysRemaining))
    }
    
    private var usageStatus: UsageStatus {
        if dataUsedGB > dataTotalGB {
            return .overLimit
        } else if predictedTotalGB > dataTotalGB {
            return .warning
        } else {
            return .onTrack
        }
    }
    
    private var statusColor: Color {
        switch usageStatus {
        case .onTrack:
            return .green
        case .warning:
            return .orange
        case .overLimit:
            return .red
        }
    }
    
    private var statusEmoji: String {
        switch usageStatus {
        case .onTrack:
            return "✅"
        case .warning:
            return "⚠️"
        case .overLimit:
            return "🚨"
        }
    }
    
    private var statusText: String {
        switch usageStatus {
        case .onTrack:
            return NSLocalizedString("status_on_track", comment: "")
        case .warning:
            return NSLocalizedString("status_warning", comment: "")
        case .overLimit:
            return NSLocalizedString("status_over_limit", comment: "")
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text(statusEmoji)
                                .font(.title)
                            
                            Text(NSLocalizedString("data_usage_prediction", comment: ""))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                                
                                Text(statusText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(statusColor)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Daily Budget Overview
                    VStack(spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("daily_budget", comment: ""))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        // Daily Budget Display
                        VStack(spacing: 12) {
                            Text(String(format: "%.2f GB", dailyBudgetGB))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Text(NSLocalizedString("per_day", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(String(format: NSLocalizedString("daily_budget_message", comment: ""), dailyBudgetGB, daysRemaining))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    
                    // Statistics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Daily Average
                        StatCard(
                            title: NSLocalizedString("daily_average", comment: ""),
                            value: String(format: "%.2f GB", dailyAverageGB),
                            subtitle: NSLocalizedString("gb_per_day", comment: ""),
                            color: .purple,
                            icon: "chart.line.uptrend.xyaxis"
                        )
                        
                        // Predicted Total
                        StatCard(
                            title: NSLocalizedString("predicted_total", comment: ""),
                            value: String(format: "%.1f GB", predictedTotalGB),
                            subtitle: NSLocalizedString("predicted_usage", comment: ""),
                            color: statusColor,
                            icon: "chart.bar.fill"
                        )
                    }
                    
                    
                    // Enhanced Usage Insights
                    if isAnalyzing {
                        VStack(spacing: 12) {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(NSLocalizedString("loading_detailed_analysis", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    } else if let insights = usageInsights {
                        enhancedInsightsView(insights: insights)
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .foregroundColor(.secondary)
                                Text(NSLocalizedString("analysis_unavailable", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            
            // Close Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }) {
                Text(NSLocalizedString("close", comment: ""))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGroupedBackground))
        )
        .onAppear {
            analyzeUsageData()
        }
        .onChange(of: dataService.cdrData) {
            // Re-analyze when CDR data becomes available
            if dataService.cdrData != nil {
                analyzeUsageData()
            }
        }
    }
    
    private func analyzeUsageData() {
        // If CDR data is already available, analyze it
        if let cdrData = dataService.cdrData {
            DispatchQueue.global(qos: .userInitiated).async {
                let insights = UsageAnalyzer.analyzeUsage(from: cdrData)
                
                DispatchQueue.main.async {
                    self.usageInsights = insights
                    self.isAnalyzing = false
                }
            }
        } else {
            // CDR data not available, try to fetch it
            if let token = authService.getAccessToken() {
                Task {
                    await dataService.fetchCdrData(accessToken: token, subscriptionGroup: subscriptionGroupId)
                    // Note: isAnalyzing will be set to false when onChange triggers
                }
            } else {
                // No token available, can't fetch data
                isAnalyzing = false
            }
        }
    }
    
    @ViewBuilder
    private func enhancedInsightsView(insights: UsageInsights) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(NSLocalizedString("usage_insights", comment: ""))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(String(format: NSLocalizedString("recent_days", comment: ""), insights.recentDaysCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Usage Pattern Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Weekday Average
                if insights.weekdayAverage > 0 {
                    InsightCard(
                        title: NSLocalizedString("weekday_average", comment: ""),
                        value: String(format: "%.0f MB", insights.weekdayAverage),
                        color: .blue,
                        icon: "calendar"
                    )
                }
                
                // Usage Trend
                InsightCard(
                    title: NSLocalizedString("usage_trend", comment: ""),
                    value: trendText(for: insights.trend),
                    color: trendColor(for: insights.trend),
                    icon: trendIcon(for: insights.trend)
                )
                
                // Weekend Average
                if insights.weekendAverage > 0 {
                    InsightCard(
                        title: NSLocalizedString("weekend_average", comment: ""),
                        value: String(format: "%.0f MB", insights.weekendAverage),
                        color: .green,
                        icon: "calendar.circle"
                    )
                }
                
                // Highest and Lowest Usage Days
                if let highest = insights.highestUsageDay {
                    InsightCard(
                        title: NSLocalizedString("highest_usage_day", comment: ""),
                        value: String(format: "%.0f MB", highest.dataUsageMB),
                        subtitle: highest.date.formatted(style: .short),
                        color: .red,
                        icon: "arrow.up.circle.fill"
                    )
                }
                
                if let lowest = insights.lowestUsageDay {
                    InsightCard(
                        title: NSLocalizedString("lowest_usage_day", comment: ""),
                        value: String(format: "%.0f MB", lowest.dataUsageMB),
                        subtitle: lowest.date.formatted(style: .short),
                        color: .mint,
                        icon: "arrow.down.circle.fill"
                    )
                }
                
                // Outliers Detection
                if !insights.outliers.isEmpty {
                    InsightCard(
                        title: NSLocalizedString("outlier_detected", comment: ""),
                        value: String(insights.outliers.count),
                        subtitle: NSLocalizedString("unusual_days", comment: ""),
                        color: .orange,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func trendIcon(for trend: UsageTrend) -> String {
        switch trend {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "minus"
        }
    }
    
    private func trendColor(for trend: UsageTrend) -> Color {
        switch trend {
        case .increasing:
            return .red
        case .decreasing:
            return .green
        case .stable:
            return .blue
        }
    }
    
    private func trendText(for trend: UsageTrend) -> String {
        switch trend {
        case .increasing:
            return NSLocalizedString("trend_increasing", comment: "")
        case .decreasing:
            return NSLocalizedString("trend_decreasing", comment: "")
        case .stable:
            return NSLocalizedString("trend_stable", comment: "")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let icon: String
    
    init(title: String, value: String, subtitle: String? = nil, color: Color, icon: String) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

enum UsageStatus {
    case onTrack
    case warning
    case overLimit
}

#Preview {
    DataUsagePredictionPopup(
        dataUsed: 8500, // 8.5 GB used
        dataTotal: 10000, // 10 GB total
        daysRemaining: 5,
        totalDaysInPeriod: 30,
        subscriptionGroupId: "test-id",
        isPresented: .constant(true)
    )
    .environmentObject(DataService())
    .environmentObject(AuthenticationService())
}
