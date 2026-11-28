import Foundation
import SwiftUI

public struct StoryOptions: Equatable {
  public var template: StoryTemplate = .editorial
  public var aspectRatio: StoryAspectRatio = .portrait
  public var background: Color = .white
  public var foreground: Color = Color(red: 0.12, green: 0.12, blue: 0.12)
  public var font: StoryFont = .serif
  public var showCompleted: Bool = true
  public var showProgress: Bool = true
  public var showBranding: Bool = true
  public var includedSections: Set<UUID> = []
  public var showUnsectioned: Bool = true
  public var dateStyle: StoryDateStyle = .full
  public var textScale: Double = 1
  public var dateScale: Double = 1

  public static let textScaleRange = 0.75...1.75
  public static let dateScaleRange = 0.75...1.50

  func bodySize(_ size: Double) -> Double {
    size * min(max(textScale, Self.textScaleRange.lowerBound), Self.textScaleRange.upperBound)
  }

  func headingSize(_ size: Double) -> Double {
    size * min(max(dateScale, Self.dateScaleRange.lowerBound), Self.dateScaleRange.upperBound)
  }

  public init() {}
  public mutating func apply(_ template: StoryTemplate) {
    self.template = template
    background = template.background
    foreground = template.foreground
    font = template == .minimal || template == .ocean ? .sans : .serif
  }
}
