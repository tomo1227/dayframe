import SwiftUI

struct StoryRow: View {
  let entry: StoryEntry
  let options: StoryOptions

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(entry.time ?? (entry.isContinuation ? "↳" : "—"))
          .font(.custom("Menlo-Regular", fixedSize: 10))
        Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 10)).accessibilityHidden(true)
      }
      .frame(width: 36, alignment: .leading)
      VStack(alignment: .leading, spacing: 0) {
        if let section = entry.section {
          Text(section).font(.custom(options.font.postScriptName, fixedSize: 10)).lineLimit(1)
            .frame(height: 18, alignment: .top)
        }
        if !entry.title.isEmpty {
          Text(entry.title).font(.custom(options.font.postScriptName, fixedSize: 16))
            .lineSpacing(2).strikethrough(entry.isCompleted)
        }
        if !entry.description.isEmpty {
          Text(entry.description).font(.custom(options.font.postScriptName, fixedSize: 11))
            .lineSpacing(2).padding(.top, 3)
        }
      }
      .frame(width: 232, alignment: .leading)
    }
    .frame(height: entry.height, alignment: .top)
    .foregroundStyle(options.foreground)
  }
}
