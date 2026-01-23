import WidgetKit
import SwiftUI

private let widgetGroupId = "group.med_tracker"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), name: "İlaç Yok", time: "--:--")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = UserDefaults.init(suiteName: widgetGroupId)
        let entry = SimpleEntry(date: Date(), name: data?.string(forKey: "medication_name") ?? "İlaç Yok", time: data?.string(forKey: "medication_time") ?? "--:--")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { (entry) in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let name: String
    let time: String
}

struct MedicationWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("SIRADAKİ İLAÇ")
                .font(.caption)
                .foregroundColor(.gray)
                .bold()
            
            Text(entry.name)
                .font(.title2) // Large Blue Text
                .foregroundColor(Color(red: 0/255, green: 80/255, blue: 158/255))
                .bold()
                .padding(.top, 2)
            
            Text(entry.time)
                .font(.largeTitle) // Red Text for Time
                .foregroundColor(.red)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

@main
struct MedicationWidget: Widget {
    let kind: String = "MedicationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MedicationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("İlaç Takip")
        .description("Sıradaki ilacınızı görün.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
