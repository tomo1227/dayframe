public enum StoryDateStyle: String, CaseIterable, Identifiable, Sendable {
  case full = "Full date"
  case short = "Short date"
  case iso = "ISO date"
  public var id: Self { self }
}
