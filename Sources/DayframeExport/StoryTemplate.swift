import SwiftUI

public enum StoryTemplate: String, CaseIterable, Identifiable, Sendable {
  case minimal = "Minimal"
  case editorial = "Editorial"
  case dark = "Dark"
  case paper = "Paper"
  case ocean = "Ocean"
  public var id: Self { self }
  public var background: Color {
    switch self {
    case .minimal, .editorial: .white
    case .dark: Color(red: 0.09, green: 0.10, blue: 0.09)
    case .paper: Color(red: 0.98, green: 0.94, blue: 0.86)
    case .ocean: Color(red: 0.89, green: 0.96, blue: 0.98)
    }
  }
  public var foreground: Color {
    switch self {
    case .minimal, .editorial: Color(red: 0.12, green: 0.12, blue: 0.12)
    case .dark: .white
    case .paper: Color(red: 0.25, green: 0.17, blue: 0.10)
    case .ocean: Color(red: 0.08, green: 0.22, blue: 0.31)
    }
  }
}
