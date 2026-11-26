public enum StoryFont: String, CaseIterable, Identifiable, Sendable {
  case serif = "Serif"
  case sans = "Sans"
  case mono = "Mono"
  public var id: Self { self }
  public var postScriptName: String {
    switch self {
    case .serif: "Georgia"
    case .sans: "HelveticaNeue"
    case .mono: "Menlo-Regular"
    }
  }
}
