import Foundation

public enum DayConflictError: LocalizedError {
  case existingDay(String)
  public var errorDescription: String? {
    switch self {
    case .existingDay(let key):
      "A plan already exists for \(key). Change the Markdown date or open that day before importing."
    }
  }
}
