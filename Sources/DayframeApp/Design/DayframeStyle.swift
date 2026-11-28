import DayframeExport
import SwiftUI

enum DayframeStyle {
  static let spacing: Double = 16
  static let margin: Double = 24

  static func accent(in scheme: ColorScheme) -> Color {
    scheme == .dark
      ? Color(red: 0.42, green: 0.82, blue: 0.70)
      : Color(red: 0.12, green: 0.46, blue: 0.37)
  }

  static func japaneseBody(relativeTo style: Font.TextStyle = .body) -> Font {
    .custom(StoryFont.sans.postScriptName, size: style == .callout ? 16 : 17, relativeTo: style)
  }

  static func japaneseHeading(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
    .custom(StoryFont.serif.postScriptName, size: size, relativeTo: style)
  }
}
