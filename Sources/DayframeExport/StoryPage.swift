public struct StoryPage: Identifiable, Equatable, Sendable {
  public let id: Int
  public let entries: [StoryEntry]
  public let total: Int
}
