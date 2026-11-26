import Foundation

public enum SyncState: Equatable, Sendable {
  case localOnly
  case checking
  case waiting
  case syncing
  case synced(Date)
  case unavailable
  case failed(String)
}
