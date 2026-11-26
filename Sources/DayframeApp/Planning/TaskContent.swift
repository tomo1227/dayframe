import DayframeCore
import SwiftUI

struct TaskContent: View {
  let task: PlanTask
  let sectionTitle: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let sectionTitle { Text(sectionTitle).font(.callout).foregroundStyle(.secondary) }
      Text(task.title).font(.body).strikethrough(task.isCompleted)
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
      if !task.description.isEmpty {
        Text(task.description).font(.callout).foregroundStyle(.secondary)
      }
    }
  }
}
