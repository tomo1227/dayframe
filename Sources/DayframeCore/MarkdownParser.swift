import Foundation

public enum MarkdownParser {
  public static func parse(
    _ markdown: String, date: Date, previous: DailyPlan? = nil, dayId: UUID? = nil
  ) -> DailyPlan {
    let lines = markdown.components(separatedBy: "\n")
    var plan = DailyPlan(
      id: dayId ?? previous?.id ?? UUID(), title: "", date: date, tasks: [], sections: [])
    var sectionId: UUID?
    var descriptionTaskId: UUID?
    var fenced = false
    for (lineNumber, raw) in lines.enumerated() {
      let line = MarkdownLine.read(raw)
      if case .fence = line {
        fenced.toggle()
        descriptionTaskId = nil
        continue
      }
      if fenced { continue }
      switch line {
      case .heading(let title):
        descriptionTaskId = nil
        plan.title = title
        if let parsed = parseDate(plan.title, relativeTo: date) { plan.date = parsed }
      case .section(let title):
        descriptionTaskId = nil
        let identity = UUID()
        plan.sections.append(
          PlanSection(
            id: identity, dayId: plan.id, title: title,
            sortOrder: plan.sections.count, sourceLine: lineNumber))
        sectionId = identity
      case .task(let title, let time, let completed):
        plan.tasks.append(
          PlanTask(
            id: UUID(), dayId: plan.id, sectionId: sectionId, title: title,
            description: "", scheduledTime: time, isCompleted: completed,
            sortOrder: plan.tasks.count, sourceLine: lineNumber))
        descriptionTaskId = plan.tasks.last?.id
      case .description(let text):
        appendDescription(text, taskId: descriptionTaskId, to: &plan)
      default: descriptionTaskId = nil
      }
    }
    if let previous { PlanIdentity.preserve(in: &plan, previous: previous) }
    return plan
  }

  private static func appendDescription(_ text: String, taskId: UUID?, to plan: inout DailyPlan) {
    guard let taskId, plan.tasks.last?.id == taskId else { return }
    let index = plan.tasks.count - 1
    if !plan.tasks[index].description.isEmpty { plan.tasks[index].description += "\n" }
    plan.tasks[index].description += text
  }

  public static func codeExcerpts(in markdown: String) -> [(sourceLine: Int, text: String)] {
    var excerpts: [(sourceLine: Int, text: String)] = []
    var block: [String] = []
    var blockStart = 0
    var followsTask = false
    for (sourceLine, raw) in markdown.components(separatedBy: "\n").enumerated() {
      let line = MarkdownLine.read(raw)
      if !block.isEmpty {
        block.append(raw)
        if case .fence = line {
          excerpts.append((blockStart, block.joined(separator: "\n")))
          block.removeAll()
        }
        continue
      }
      switch line {
      case .fence:
        blockStart = sourceLine
        block = [raw]
        followsTask = false
      case .task:
        followsTask = true
      case .section:
        followsTask = false
      case .description where followsTask:
        break
      default:
        followsTask = false
        if raw.contains("`") { excerpts.append((sourceLine, raw)) }
      }
    }
    if !block.isEmpty { excerpts.append((blockStart, block.joined(separator: "\n"))) }
    return excerpts
  }

  public static func settingCompletion(_ completed: Bool, task: PlanTask, in markdown: String)
    -> String
  {
    var lines = markdown.components(separatedBy: "\n")
    guard lines.indices.contains(task.sourceLine) else { return markdown }
    let raw = lines[task.sourceLine]
    let indent = String(raw.prefix(while: { $0.isWhitespace }))
    var content = String(raw.dropFirst(indent.count + 2))
    if content.hasPrefix("[ ] ") || content.lowercased().hasPrefix("[x] ") {
      content = String(content.dropFirst(4))
    }
    lines[task.sourceLine] = "\(indent)- [\(completed ? "x" : " ")] \(content)"
    return lines.joined(separator: "\n")
  }

  public static func parseDate(_ title: String, relativeTo date: Date) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.defaultDate = date
    formatter.isLenient = false
    for format in ["yyyy-MM-dd", "EEEE, MMMM d, yyyy", "MMMM d, yyyy", "EEEE, MMMM d", "yyyy年M月d日"]
    {
      formatter.dateFormat = format
      if let parsed = formatter.date(from: title) { return parsed }
    }
    return nil
  }
}
