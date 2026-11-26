import Foundation

public struct PlanSection: Identifiable, Equatable, Sendable, Codable {
  public var id: UUID
  public var dayId: UUID
  public var title: String
  public var sortOrder: Int
  public var sourceLine: Int
}
