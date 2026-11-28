import DayframeCore
import SwiftUI

public struct StoryCanvas: View {
  public let plan: DailyPlan
  public let page: StoryPage
  public let options: StoryOptions
  public let locale: Locale

  public init(plan: DailyPlan, page: StoryPage, options: StoryOptions, locale: Locale) {
    self.plan = plan
    self.page = page
    self.options = options
    self.locale = locale
  }

  public var body: some View {
    let aspectRatio = options.aspectRatio
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(plan.date.formatted(.dateTime.weekday(.wide).locale(locale)).uppercased())
          .font(.custom(StoryFont.sans.postScriptName, fixedSize: 10))
        Spacer()
        Image(systemName: "sun.max").font(.system(size: 16)).accessibilityHidden(true)
      }
      .padding(.bottom, 12)
      Text(dateLabel)
        .font(
          .custom(
            options.font.postScriptName,
            fixedSize: options.headingSize(options.template == .editorial ? 32 : 24))
        )
        .lineLimit(2).minimumScaleFactor(0.65)
        .padding(.bottom, 8)
      Rectangle().fill(options.foreground).frame(height: options.template == .editorial ? 2 : 0.5)
        .padding(.bottom, 18)
      VStack(alignment: .leading, spacing: 0) {
        ForEach(page.entries) { entry in StoryRow(entry: entry, options: options) }
      }
      Spacer(minLength: 12)
      if options.showProgress {
        HStack {
          Image(systemName: "checkmark.circle").accessibilityHidden(true)
          Text("\(plan.completedCount) / \(plan.tasks.count)")
        }
        .font(.custom("HelveticaNeue", fixedSize: 11)).padding(.bottom, 12)
      }
      HStack {
        if options.showBranding { Text("DAYFRAME").font(.custom("HelveticaNeue", fixedSize: 9)) }
        Spacer()
        if page.total > 1 {
          Text("\(page.id + 1) / \(page.total)").font(.custom("HelveticaNeue", fixedSize: 9))
        }
      }
    }
    .padding(.horizontal, StoryAspectRatio.horizontalInset)
    .padding(.vertical, aspectRatio.verticalInset)
    .frame(width: aspectRatio.canvasSize.width, height: aspectRatio.canvasSize.height)
    .foregroundStyle(options.foreground)
    .background(options.background)
    .environment(\.colorScheme, options.template == .dark ? .dark : .light)
    .environment(\.dynamicTypeSize, .medium)
  }

  private var dateLabel: String {
    switch options.dateStyle {
    case .full: plan.date.formatted(.dateTime.month(.wide).day().year().locale(locale))
    case .short: plan.date.formatted(.dateTime.month(.abbreviated).day().locale(locale))
    case .iso: plan.date.formatted(.iso8601.year().month().day().dateSeparator(.dash))
    }
  }
}
