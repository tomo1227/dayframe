import DayframeCore
import SwiftUI

struct TaskContent: View {
  let task: PlanTask
  let sectionTitle: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let sectionTitle {
        Text(sectionTitle).font(DayframeStyle.japaneseBody(relativeTo: .callout))
          .foregroundStyle(.secondary)
      }
      Text(task.title).font(DayframeStyle.japaneseBody()).strikethrough(task.isCompleted)
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
      if !task.description.isEmpty {
        Text(task.description).font(DayframeStyle.japaneseBody(relativeTo: .callout))
          .foregroundStyle(.secondary)
      }
    }
  }
}
