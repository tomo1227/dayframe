import DayframeCore
import SwiftUI

struct TaskActionsMenu: View {
  let task: PlanTask
  let session: EditorSession
  let edit: (PlanTask) -> Void

  var body: some View {
    Menu("Task actions", systemImage: "ellipsis") {
      Button("Edit task", systemImage: "pencil", action: editTask)
      Button("Move up", systemImage: "arrow.up", action: moveUp)
      Button("Move down", systemImage: "arrow.down", action: moveDown)
      Button("Delete task", systemImage: "trash", role: .destructive, action: delete)
    }
    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
  }
  private func editTask() { edit(task) }
  private func moveUp() { session.move(task, by: -1) }
  private func moveDown() { session.move(task, by: 1) }
  private func delete() { session.delete(task) }
}
