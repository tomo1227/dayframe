import DayframeCore
import SwiftUI

struct TaskGroup: View {
  let title: String
  let tasks: [PlanTask]
  let session: EditorSession
  let edit: (PlanTask) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title).font(.headline).foregroundStyle(.secondary).padding(.top, 24).padding(.bottom, 12)
      ForEach(tasks) { task in
        TaskRow(task: task, session: session, edit: edit)
        Divider()
      }
    }
  }
}
