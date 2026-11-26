import CoreText
import DayframeCore
import Foundation

public enum StoryPaginator {
  public static func pages(for plan: DailyPlan, options: StoryOptions) -> [StoryPage] {
    var pages: [[StoryEntry]] = [[]]
    var used: Double = 0
    let tasks = plan.tasks.filter { task in
      (options.showCompleted || !task.isCompleted)
        && (task.sectionId.map(options.includedSections.contains) ?? options.showUnsectioned)
    }
    for task in tasks {
      let titleLines = wrap(task.title, width: 232, size: 16, font: options.font)
      let descriptionLines = wrap(task.description, width: 232, size: 11, font: options.font)
      var titleIndex = 0
      var descriptionIndex = 0
      var segment = 0
      repeat {
        let titles = Array(titleLines.dropFirst(titleIndex).prefix(5))
        titleIndex += titles.count
        let descriptions =
          titleIndex == titleLines.count
          ? Array(descriptionLines.dropFirst(descriptionIndex).prefix(6)) : []
        descriptionIndex += descriptions.count
        let section = task.sectionId.flatMap { id in plan.sections.first { $0.id == id }?.title }
        let height =
          Double(titles.count) * 21 + Double(descriptions.count) * 15 + (section == nil ? 0 : 18)
          + 14
        if used + height > 330, !pages[pages.count - 1].isEmpty {
          pages.append([])
          used = 0
        }
        pages[pages.count - 1].append(
          StoryEntry(
            id: "\(task.id)-\(segment)",
            title: titles.joined(separator: "\n"),
            description: descriptions.joined(separator: "\n"),
            section: section, time: segment == 0 ? task.scheduledTime : nil,
            isCompleted: task.isCompleted, isContinuation: segment > 0, height: height))
        used += height
        segment += 1
      } while titleIndex < titleLines.count || descriptionIndex < descriptionLines.count
    }
    return pages.enumerated().map {
      StoryPage(id: $0.offset, entries: $0.element, total: pages.count)
    }
  }

  private static func wrap(_ text: String, width: Double, size: Double, font: StoryFont) -> [String]
  {
    guard !text.isEmpty else { return [] }
    var result: [String] = []
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(
        font.postScriptName as CFString, size, nil)
    ]
    for paragraph in text.components(separatedBy: "\n") {
      let attributed = NSAttributedString(string: paragraph, attributes: attributes)
      let typesetter = CTTypesetterCreateWithAttributedString(attributed)
      let source = paragraph as NSString
      var position = 0
      while position < source.length {
        let count = max(1, CTTypesetterSuggestLineBreak(typesetter, position, width))
        result.append(source.substring(with: NSRange(location: position, length: count)))
        position += count
      }
    }
    return result
  }
}
