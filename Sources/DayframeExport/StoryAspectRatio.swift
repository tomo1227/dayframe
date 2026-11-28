import Foundation

public enum StoryAspectRatio: String, CaseIterable, Identifiable, Sendable {
  case portrait = "9:16"
  case landscape = "16:9"
  case landscapeWide = "16:10"
  case post = "4:5"

  public var id: Self { self }

  public var canvasSize: CGSize {
    switch self {
    case .portrait: CGSize(width: 360, height: 640)
    case .landscape: CGSize(width: 640, height: 360)
    case .landscapeWide: CGSize(width: 640, height: 400)
    case .post: CGSize(width: 360, height: 450)
    }
  }

  static let horizontalInset = 40.0
  static let rowMarkerWidth = 36.0
  static let rowSpacing = 12.0

  var verticalInset: Double {
    switch self {
    case .portrait: 60
    case .landscape, .landscapeWide: 28
    case .post: 40
    }
  }

  var rowTextWidth: Double {
    canvasSize.width - 2 * Self.horizontalInset - Self.rowMarkerWidth - Self.rowSpacing
  }

  var rowsHeight: Double {
    // Leave space for a two-line date, the divider, progress, and the page footer.
    canvasSize.height - 2 * verticalInset - 190
  }
}
