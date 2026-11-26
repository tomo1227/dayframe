import Foundation

public enum MarkdownEditing {
  public static func taskLine(title: String, time: String, completed: Bool) -> String {
    let prefix = time.isEmpty ? "" : "\(time) "
    return
      "- [\(completed ? "x" : " ")] \(prefix)\(title.trimmingCharacters(in: .whitespacesAndNewlines))"
  }

  public static func replacingTask(
    _ task: PlanTask, title: String, time: String,
    description: String, in markdown: String
  ) -> String {
    var lines = markdown.components(separatedBy: "\n")
    guard let range = block(for: task, lines: lines) else { return markdown }
    var replacement = [taskLine(title: title, time: time, completed: task.isCompleted)]
    if !description.isEmpty {
      replacement += description.components(separatedBy: "\n").map { "  \($0)" }
    }
    lines.replaceSubrange(range, with: replacement)
    return lines.joined(separator: "\n")
  }

  public static func deletingTask(_ task: PlanTask, in markdown: String) -> String {
    var lines = markdown.components(separatedBy: "\n")
    guard let range = block(for: task, lines: lines) else { return markdown }
    lines.removeSubrange(range)
    return lines.joined(separator: "\n")
  }

  public static func addingTask(
    title: String, time: String, description: String,
    section: PlanSection?, plan: DailyPlan, in markdown: String
  ) -> String {
    var lines = markdown.components(separatedBy: "\n")
    let nextSection = plan.sections.first { $0.sourceLine > (section?.sourceLine ?? -1) }
    let insertion = nextSection?.sourceLine ?? lines.count
    var newLines = [taskLine(title: title, time: time, completed: false)]
    if !description.isEmpty {
      newLines += description.components(separatedBy: "\n").map { "  \($0)" }
    }
    lines.insert(contentsOf: newLines, at: insertion)
    return lines.joined(separator: "\n")
  }

  public static func movingTask(
    _ task: PlanTask, by offset: Int, plan: DailyPlan, in markdown: String
  ) -> String {
    let siblings = plan.tasks.filter { $0.sectionId == task.sectionId }
    guard let index = siblings.firstIndex(where: { $0.id == task.id }),
      siblings.indices.contains(index + offset)
    else { return markdown }
    let other = siblings[index + offset]
    var lines = markdown.components(separatedBy: "\n")
    guard let first = block(for: task, lines: lines), let second = block(for: other, lines: lines)
    else { return markdown }
    let lower = first.lowerBound < second.lowerBound ? first : second
    let upper = first.lowerBound < second.lowerBound ? second : first
    let lowerContent = Array(lines[lower])
    let upperContent = Array(lines[upper])
    lines.replaceSubrange(upper, with: lowerContent)
    lines.replaceSubrange(lower, with: upperContent)
    return lines.joined(separator: "\n")
  }

  public static func renamingSection(_ section: PlanSection, title: String, in markdown: String)
    -> String
  {
    var lines = markdown.components(separatedBy: "\n")
    guard lines.indices.contains(section.sourceLine) else { return markdown }
    lines[section.sourceLine] = "## \(title.trimmingCharacters(in: .whitespacesAndNewlines))"
    return lines.joined(separator: "\n")
  }

  public static func validTime(_ value: String) -> Bool {
    value.isEmpty
      || value.range(of: #"^(?:[01]\d|2[0-3]):[0-5]\d$"#, options: .regularExpression) != nil
  }

  private static func block(for task: PlanTask, lines: [String]) -> Range<Int>? {
    guard lines.indices.contains(task.sourceLine) else { return nil }
    var end = task.sourceLine + 1
    while lines.indices.contains(end), lines[end].hasPrefix("  "),
      !lines[end].trimmingCharacters(in: .whitespaces).isEmpty
    { end += 1 }
    return task.sourceLine..<end
  }
}
