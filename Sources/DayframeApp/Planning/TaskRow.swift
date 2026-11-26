import DayframeCore
import SwiftUI

struct TaskRow: View {
  @Environment(\.dynamicTypeSize) private var typeSize
  @ScaledMetric(relativeTo: .callout) private var timeWidth = 56.0
  let task: PlanTask
  let session: EditorSession
  let edit: (PlanTask) -> Void

  var body: some View {
    Group {
      if typeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            if let time = task.scheduledTime {
              Text(time).font(.callout.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            TaskCompletionButton(task: task, session: session)
            TaskActionsMenu(task: task, session: session, edit: edit)
          }
          TaskContent(task: task, sectionTitle: sectionTitle)
        }
        .padding(.vertical, 12)
      } else {
        HStack(alignment: .top, spacing: DayframeStyle.spacing) {
          if let time = task.scheduledTime {
            Text(time).font(.callout.monospaced()).foregroundStyle(.secondary)
              .frame(width: timeWidth, alignment: .leading).padding(.top, 12)
          }
          TaskCompletionButton(task: task, session: session)
          TaskContent(task: task, sectionTitle: sectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
          TaskActionsMenu(task: task, session: session, edit: edit)
        }
      }
    }
    .contextMenu {
      Button("Edit task", systemImage: "pencil", action: editTask)
      Button("Delete task", systemImage: "trash", role: .destructive, action: delete)
    }
  }

  private var sectionTitle: String? {
    session.plan.sections.first { $0.id == task.sectionId }?.title
  }
  private func editTask() { edit(task) }
  private func delete() { session.delete(task) }
}
