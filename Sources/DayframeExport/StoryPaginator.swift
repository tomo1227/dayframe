import CoreText
import DayframeCore
import Foundation

public enum StoryPaginator {
  public static func pages(
    for plan: DailyPlan, options: StoryOptions, markdown: String = ""
  ) -> [StoryPage] {
    var pages: [[StoryEntry]] = [[]]
    var used: Double = 0
    let sections = Dictionary(uniqueKeysWithValues: plan.sections.map { ($0.id, $0.title) })
    let excerpts = MarkdownParser.codeExcerpts(in: markdown)
    var nextExcerpt = 0
    let pageHeight = options.aspectRatio.rowsHeight
    let textWidth = options.aspectRatio.rowTextWidth
    let titleHeight = options.bodySize(21)
    let descriptionHeight = options.bodySize(15)

    func append(
      id: String, title: String, description: String = "", section: String? = nil,
      time: String? = nil, completed: Bool = false, isCode: Bool = false
    ) {
      let font: StoryFont = isCode ? .mono : options.font
      let titleLines = wrap(
        title, width: textWidth, size: options.bodySize(16), font: font, preserveEmptyLines: isCode)
      let descriptionLines = wrap(
        description, width: textWidth, size: options.bodySize(11), font: font)
      let padding = 14 + (section == nil ? 0 : options.bodySize(18))
      let titleCapacity = Int((pageHeight - padding) / titleHeight)
      let descriptionCapacity = { (titleCount: Int) in
        max(0, Int((pageHeight - padding - Double(titleCount) * titleHeight) / descriptionHeight))
      }
      var titleIndex = 0
      var descriptionIndex = 0
      var segment = 0
      repeat {
        let titles = Array(titleLines.dropFirst(titleIndex).prefix(min(isCode ? 8 : 5, titleCapacity)))
        titleIndex += titles.count
        let descriptions =
          titleIndex == titleLines.count
          ? Array(
            descriptionLines.dropFirst(descriptionIndex).prefix(
              min(6, descriptionCapacity(titles.count))))
          : []
        descriptionIndex += descriptions.count
        let height =
          Double(titles.count) * titleHeight
          + Double(descriptions.count) * descriptionHeight + padding
        if used + height > pageHeight, !pages[pages.count - 1].isEmpty {
          pages.append([])
          used = 0
        }
        pages[pages.count - 1].append(
          StoryEntry(
            id: "\(id)-\(segment)", title: titles.joined(separator: "\n"),
            description: descriptions.joined(separator: "\n"), section: section,
            time: segment == 0 ? time : nil, isCompleted: completed,
            isContinuation: segment > 0, isCode: isCode, height: height))
        used += height
        segment += 1
      } while titleIndex < titleLines.count || descriptionIndex < descriptionLines.count
    }

    func appendExcerpts(before sourceLine: Int) {
      while nextExcerpt < excerpts.count, excerpts[nextExcerpt].sourceLine < sourceLine {
        let excerpt = excerpts[nextExcerpt]
        append(id: "code-\(excerpt.sourceLine)", title: excerpt.text, isCode: true)
        nextExcerpt += 1
      }
    }

    for task in plan.tasks {
      appendExcerpts(before: task.sourceLine)
      guard options.showCompleted || !task.isCompleted,
        task.sectionId.map(options.includedSections.contains) ?? options.showUnsectioned
      else { continue }
      append(
        id: task.id.uuidString, title: task.title, description: task.description,
        section: task.sectionId.flatMap { sections[$0] }, time: task.scheduledTime,
        completed: task.isCompleted)
    }
    appendExcerpts(before: .max)
    return pages.enumerated().map {
      StoryPage(id: $0.offset, entries: $0.element, total: pages.count)
    }
  }

  private static func wrap(
    _ text: String, width: Double, size: Double, font: StoryFont, preserveEmptyLines: Bool = false
  ) -> [String] {
    guard !text.isEmpty else { return [] }
    var result: [String] = []
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(
        font.postScriptName as CFString, size, nil)
    ]
    for paragraph in text.components(separatedBy: "\n") {
      if paragraph.isEmpty && preserveEmptyLines {
        result.append("")
        continue
      }
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
