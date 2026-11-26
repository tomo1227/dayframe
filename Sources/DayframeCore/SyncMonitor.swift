import CloudKit
import CoreData
import Foundation
import Observation

@MainActor @Observable
public final class SyncMonitor {
  public private(set) var state: SyncState
  private let cloudIdentifier: String?
  @ObservationIgnored private var observer: NSObjectProtocol?
  private var activeEvents: Set<UUID> = []

  public init(cloudIdentifier: String?, startupFailure: String? = nil) {
    self.cloudIdentifier = cloudIdentifier
    state = cloudIdentifier == nil ? .localOnly : .checking
    if let startupFailure { state = .failed(startupFailure) }
  }

  public func start() async {
    guard let cloudIdentifier else { return }
    if observer == nil {
      observer = NotificationCenter.default.addObserver(
        forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard
          let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event
        else { return }
        let identifier = event.identifier
        let ended = event.endDate
        let succeeded = event.succeeded
        let failure = event.error?.localizedDescription
        let isTransfer = event.type != .setup
        Task { @MainActor [weak self] in
          self?.receive(
            id: identifier, ended: ended, succeeded: succeeded,
            failure: failure, isTransfer: isTransfer)
        }
      }
    }
    do {
      let status = try await CKContainer(identifier: cloudIdentifier).accountStatus()
      if status != .available {
        state = .unavailable
      } else if state == .checking || state == .unavailable {
        state = .waiting
      }
    } catch { state = .failed(error.localizedDescription) }
  }

  public func markPending() {
    guard cloudIdentifier != nil else { return }
    if case .unavailable = state { return }
    if case .failed = state { return }
    state = activeEvents.isEmpty ? .waiting : .syncing
  }

  public func stop() {
    if let observer { NotificationCenter.default.removeObserver(observer) }
    observer = nil
  }

  private func receive(id: UUID, ended: Date?, succeeded: Bool, failure: String?, isTransfer: Bool)
  {
    guard let ended else {
      activeEvents.insert(id)
      state = .syncing
      return
    }
    activeEvents.remove(id)
    if let failure {
      state = .failed(failure)
    } else if succeeded && isTransfer {
      state = activeEvents.isEmpty ? .synced(ended) : .syncing
    } else if activeEvents.isEmpty {
      state = .waiting
    }
  }
}
