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
            
            if dataAssigned > 0 {
                let dataUsed = dataAssigned - dataAvailable
                return SimpleEntry(date: Date(), dataUsed: dataUsed, dataTotal: dataAssigned)
            }
        }
        
        return SimpleEntry.placeholder()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dataUsed: Double
    let dataTotal: Double
        
    static func placeholder() -> SimpleEntry {
        SimpleEntry(date: Date(), dataUsed: 15000, dataTotal: 20000) // 15GB of 20GB
    }
}

struct DataCheckWidgetEntryView : View {
    var entry: Provider.Entry
    
    private var percentage: Double {
        guard entry.dataTotal > 0 else { return 0 }
        return (entry.dataUsed / entry.dataTotal) * 100
    }
    
    private var dataUsedInGB: Double {
        return entry.dataUsed / 1000
    }
    
    private var dataTotalInGB: Double {
        return entry.dataTotal / 1000
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("📶")
                        .font(.title3)
                    Text("Data")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.7), .blue]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                        .animation(.easeInOut(duration: 1.0), value: percentage)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(dataUsedInGB, specifier: "%.1f") GB used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(dataTotalInGB, specifier: "%.0f") GB total")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
