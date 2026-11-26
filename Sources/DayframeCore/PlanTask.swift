import Foundation

public struct PlanTask: Identifiable, Equatable, Sendable, Codable {
  public var id: UUID
  public var dayId: UUID
  public var sectionId: UUID?
  public var title: String
  public var description: String
  public var scheduledTime: String?
  public var isCompleted: Bool
  public var sortOrder: Int
  public var sourceLine: Int
}
