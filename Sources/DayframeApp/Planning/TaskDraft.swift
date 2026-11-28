import DayframeCore
import Foundation

struct TaskDraft: Identifiable {
  let id = UUID()
  var task: PlanTask?
  var title: String = ""
  var time: String = ""
  var description: String = ""
  var sectionId: UUID?

  private static let defaultTime = "09:00"
  private static let timeCalendar = Calendar(identifier: .iso8601)

  var hasScheduledTime: Bool {
    get { !time.isEmpty }
    set {
      if newValue {
        if time.isEmpty { time = Self.defaultTime }
      } else {
        time = ""
      }
    }
  }

  var pickerTime: Date {
    get {
      let parts = time.split(separator: ":")
      let hour = parts.first.flatMap { Int($0) } ?? 9
      let minute = parts.dropFirst().first.flatMap { Int($0) } ?? 0
      // A fixed UTC day represents a clock time without daylight-saving gaps.
      return Date(timeIntervalSince1970: TimeInterval(hour * 3600 + minute * 60))
    }
    set {
      let parts = Self.timeCalendar.dateComponents(in: .gmt, from: newValue)
      if let hour = parts.hour, let minute = parts.minute {
        time = String(format: "%02d:%02d", hour, minute)
      }
    }
  }

  init(task: PlanTask? = nil) {
    self.task = task
    title = task?.title ?? ""
    time = task?.scheduledTime ?? ""
    description = task?.description ?? ""
    sectionId = task?.sectionId
  }
}
