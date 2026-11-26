import DayframeCore
import SwiftUI

struct TaskCompletionButton: View {
  let task: PlanTask
  let session: EditorSession

  var body: some View {
    Button(
      task.isCompleted ? "Mark incomplete" : "Mark complete",
      systemImage: task.isCompleted ? "checkmark.circle.fill" : "circle", action: toggle
    )
    .labelStyle(.iconOnly).font(.title3)
    .foregroundStyle(task.isCompleted ? DayframeStyle.accent : .secondary)
    .frame(minWidth: 44, minHeight: 44)
    .buttonStyle(.plain)
    .accessibilityLabel(
      Text(
        "\(task.title), \(task.isCompleted ? String(localized: "Completed") : String(localized: "Incomplete"))"
      )
    )
    .accessibilityIdentifier("task-completion-\(task.title)")
  }
  private func toggle() { session.toggle(task) }
}
