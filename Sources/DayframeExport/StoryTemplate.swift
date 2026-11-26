import SwiftUI

public enum StoryTemplate: String, CaseIterable, Identifiable, Sendable {
  case minimal = "Minimal"
  case editorial = "Editorial"
  case dark = "Dark"
  public var id: Self { self }
  public var background: Color {
    self == .dark ? Color(red: 0.09, green: 0.10, blue: 0.09) : .white
  }
  public var foreground: Color {
    self == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.12)
  }
}
