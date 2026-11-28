import Foundation

enum MarkdownLine {
  case heading(String)
  case section(String)
  case task(String, String?, Bool)
  case description(String)
  case fence
  case ignored

  static func read(_ raw: String) -> MarkdownLine {
    let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if line.hasPrefix("```") || line.hasPrefix("~~~") { return .fence }
    if line.hasPrefix("# ") { return .heading(String(line.dropFirst(2))) }
    if line.hasPrefix("## ") { return .section(String(line.dropFirst(3))) }
    if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
      return readTask(String(line.dropFirst(2)))
    }
    if let note = taskNote(in: raw) { return .description(note) }
    if !line.isEmpty, raw.hasPrefix("  ") { return .description(line) }
    return .ignored
  }

  static func taskNote(in raw: String) -> String? {
    guard raw.hasPrefix(MarkdownEditing.taskNotePrefix) else { return nil }
    let text = raw.dropFirst(MarkdownEditing.taskNotePrefix.count)
      .trimmingCharacters(in: .whitespaces)
    return text.isEmpty ? nil : text
  }

  private static func readTask(_ value: String) -> MarkdownLine {
    var title = value
    let completed = title.lowercased().hasPrefix("[x] ")
    if title.hasPrefix("[ ] ") || completed { title = String(title.dropFirst(4)) }
    var time: String?
    if let range = title.range(of: #"^(?:[01]\d|2[0-3]):[0-5]\d\s+"#, options: .regularExpression) {
      time = String(title[range].prefix(5))
      title.removeSubrange(range)
    }
    return title.isEmpty ? .ignored : .task(title, time, completed)
  }
}
