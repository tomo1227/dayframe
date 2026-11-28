import SwiftUI

struct StoryRow: View {
  let entry: StoryEntry
  let options: StoryOptions

  var body: some View {
    HStack(alignment: .top, spacing: StoryAspectRatio.rowSpacing) {
      VStack(alignment: .leading, spacing: 6) {
        if !entry.isCode {
          Text(entry.time ?? (entry.isContinuation ? "↳" : "—"))
            .font(.custom("Menlo-Regular", fixedSize: options.bodySize(10)))
            .minimumScaleFactor(0.65)
            .lineLimit(1)
          Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: options.bodySize(10))).accessibilityHidden(true)
        }
      }
      .frame(width: StoryAspectRatio.rowMarkerWidth, alignment: .leading)
      VStack(alignment: .leading, spacing: 0) {
        if let section = entry.section {
          Text(verbatim: section)
            .font(.custom(options.font.postScriptName, fixedSize: options.bodySize(10)))
            .lineLimit(1)
            .frame(height: options.bodySize(18), alignment: .top)
        }
        if !entry.title.isEmpty {
          Text(verbatim: entry.title)
            .font(
              .custom(
                (entry.isCode ? StoryFont.mono : options.font).postScriptName,
                fixedSize: options.bodySize(16))
            )
            .lineSpacing(2).strikethrough(entry.isCompleted)
        }
        if !entry.description.isEmpty {
          Text(verbatim: entry.description)
            .font(.custom(options.font.postScriptName, fixedSize: options.bodySize(11)))
            .lineSpacing(2).padding(.top, 3)
        }
      }
      .frame(width: options.aspectRatio.rowTextWidth, alignment: .leading)
    }
    .frame(height: entry.height, alignment: .top)
    .foregroundStyle(options.foreground)
  }
}
