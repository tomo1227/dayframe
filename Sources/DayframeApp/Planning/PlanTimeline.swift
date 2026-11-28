import DayframeCore
import SwiftUI

struct PlanTimeline: View {
  @Environment(\.locale) private var locale
  let session: EditorSession
  let edit: (PlanTask) -> Void

  var body: some View {
    let timed = session.plan.tasks.filter { $0.scheduledTime != nil }
    let untimed = session.plan.tasks.filter { $0.scheduledTime == nil }
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .firstTextBaseline) {
          Text(session.plan.date, format: .dateTime.weekday(.wide).locale(locale))
            .font(DayframeStyle.japaneseHeading(size: 20, relativeTo: .title3))
            .textCase(.uppercase)
          Spacer()
          Image(systemName: "sun.max").foregroundStyle(.tint).accessibilityHidden(true)
        }
        Text(session.plan.date, format: .dateTime.month(.wide).day().year().locale(locale))
          .font(DayframeStyle.japaneseHeading(size: 34, relativeTo: .largeTitle))
        if !session.plan.title.isEmpty,
          MarkdownParser.parseDate(session.plan.title, relativeTo: session.record.displayDate())
            == nil
        {
          Text(session.plan.title)
            .font(DayframeStyle.japaneseHeading(size: 22, relativeTo: .title2))
        }
        ProgressView(value: session.plan.progress)
          .accessibilityLabel("Completion")
        Text("\(session.plan.completedCount) / \(session.plan.tasks.count) completed")
          .font(.callout).foregroundStyle(.secondary)
        if session.plan.tasks.isEmpty {
          ContentUnavailableView("An open day", systemImage: "sun.max", description: Text(""))
        }
        TaskGroup(title: String(localized: "Timeline"), tasks: timed, session: session, edit: edit)
        if !untimed.isEmpty {
          TaskGroup(
            title: String(localized: "Anytime"), tasks: untimed, session: session, edit: edit)
        }
      }
      .padding(DayframeStyle.margin).frame(maxWidth: 720)
      .frame(maxWidth: .infinity)
    }
  }
}
