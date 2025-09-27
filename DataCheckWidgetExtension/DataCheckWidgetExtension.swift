//
//  DataCheckWidget.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        if context.isPreview {
            completion(SimpleEntry.placeholder())
            return
        }
        completion(readDataFromUserDefaults())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = readDataFromUserDefaults()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func readDataFromUserDefaults() -> SimpleEntry {
        // IMPORTANT: Replace "group.com.yourcompany.DataCheck" with your App Group ID
        if let userDefaults = UserDefaults(suiteName: "group.shadowfly.DataCheck") {
            let dataAvailable = userDefaults.double(forKey: "dataAvailable")
            let dataAssigned = userDefaults.double(forKey: "dataAssigned")
            let daysRemaining = userDefaults.integer(forKey: "daysRemaining")
            
            if dataAssigned > 0 {
                let dataUsed = dataAssigned - dataAvailable
                return SimpleEntry(date: Date(), dataUsed: dataUsed, dataTotal: dataAssigned, daysRemaining: daysRemaining)
            }
        }
        
        return SimpleEntry.placeholder()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dataUsed: Double
    let dataTotal: Double
    let daysRemaining: Int
        
    static func placeholder() -> SimpleEntry {
        SimpleEntry(date: Date(), dataUsed: 15000, dataTotal: 20000, daysRemaining: 12) // 15GB of 20GB, 12 days left
    }
}

struct DataCheckWidgetEntryView : View {
    var entry: Provider.Entry
    
    private var dataPercentage: Double {
        guard entry.dataTotal > 0 else { return 0 }
        return (entry.dataUsed / entry.dataTotal)
    }
    
    private var dataUsedInGB: Double {
        return entry.dataUsed / 1000
    }
    
    private var daysPercentage: Double {
        // Assuming a 30-day billing cycle for the progress calculation
        let totalDays = 30.0
        let daysUsed = totalDays - Double(entry.daysRemaining)
        return min(daysUsed / totalDays, 1.0)
    }

    var body: some View {
        ZStack {
            // Outer circle background (Data consumption) - Gray
            Circle()
                .stroke(Color(.systemGray3), lineWidth: 13.6)
                .aspectRatio(1, contentMode: .fit)
                .padding(2)
            
            // Outer circle progress (Data consumption) - Green
            Circle()
                .trim(from: 0, to: dataPercentage)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0x32/255, green: 0xa6/255, blue: 0x08/255),
                            Color(red: 0x48/255, green: 0xed/255, blue: 0x0c/255)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 13.6, lineCap: .round)
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: dataPercentage)
            
            // Inner circle progress (Days remaining) - Blue
            Circle()
                .trim(from: 0, to: daysPercentage)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0x0e/255, green: 0x54/255, blue: 0x8a/255),
                            Color(red: 0x26/255, green: 0x95/255, blue: 0xeb/255)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(12)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: daysPercentage)
            
            // Center content
            VStack(spacing: 2) {
                // GB label (small, above the number)
                Text("GB")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                // Data usage (big number in center)
                Text("\(dataUsedInGB, specifier: "%.1f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Days remaining text (small, below the number)
                Text("\(entry.daysRemaining) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct DataCheckWidget: Widget {
    let kind: String = "DataCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DataCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Data Usage")
        .description("Check your data usage at a glance.")
    }
}

#Preview(as: .systemSmall) {
    DataCheckWidget()
} timeline: {
    SimpleEntry.placeholder()
}
