import DayframeCore
import Foundation

struct TaskDraft: Identifiable {
  let id = UUID()
  var task: PlanTask?
  var title: String = ""
  var time: String = ""
  var description: String = ""
  var sectionId: UUID?

  init(task: PlanTask? = nil) {
    self.task = task
    title = task?.title ?? ""
    time = task?.scheduledTime ?? ""
    description = task?.description ?? ""
    sectionId = task?.sectionId
  }
}
