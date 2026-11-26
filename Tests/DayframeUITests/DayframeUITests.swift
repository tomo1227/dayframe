import XCTest

@MainActor
final class DayframeUITests: XCTestCase {
  #if os(iOS)
    func testCalendarWheelBrowsesWithoutOpeningPlan() throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()
      let newTask = app.buttons["new-task"]
      XCTAssertTrue(newTask.waitForExistence(timeout: 10))
      app.navigationBars.buttons.firstMatch.tap()
      let monthPicker = app.buttons["calendar-month-picker"]
      XCTAssertTrue(monthPicker.waitForExistence(timeout: 5))
      monthPicker.tap()
      XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
      let calendar = Calendar(identifier: .gregorian)
      let targetDate = try XCTUnwrap(calendar.date(byAdding: .year, value: 1, to: .now))
      let targetYear = String(calendar.component(.year, from: targetDate))
      let yearWheel = try XCTUnwrap(app.pickerWheels.allElementsBoundByIndex.last)
      yearWheel.adjust(toPickerWheelValue: targetYear)
      XCTAssertTrue(yearWheel.exists)
      XCTAssertFalse(newTask.exists)
      monthPicker.tap()
      let dayID = targetDate.formatted(
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
      let day = app.buttons["calendar-day-\(dayID)"]
      XCTAssertTrue(day.waitForExistence(timeout: 5))
      day.tap()
      XCTAssertTrue(newTask.waitForExistence(timeout: 5))
      let dateLabel = targetDate.formatted(
        .dateTime.month(.wide).day().year().locale(Locale(identifier: "en_US")))
      XCTAssertTrue(app.staticTexts[dateLabel].exists)
    }

    func testCalendarSelectionOpensPlanWithoutListingEmptyDays() throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 10))
      let back = app.navigationBars.buttons.firstMatch
      back.tap()
      XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 5))
      let today = Date.now
      let calendar = Calendar(identifier: .gregorian)
      let offset = calendar.component(.day, from: today) > 1 ? -1 : 1
      let otherDay = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: today))
      let locale = Locale(identifier: "en_US")
      let dayID = otherDay.formatted(
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
      let dayButton = app.buttons["calendar-day-\(dayID)"]
      XCTAssertTrue(dayButton.waitForExistence(timeout: 5))
      app.buttons["Next month"].tap()
      XCTAssertFalse(dayButton.exists)
      app.buttons["Previous month"].tap()
      XCTAssertTrue(dayButton.waitForExistence(timeout: 5))
      dayButton.tap()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 5))
      let dateLabel = otherDay.formatted(.dateTime.month(.wide).day().year().locale(locale))
      XCTAssertTrue(app.staticTexts[dateLabel].exists)
      back.tap()
      XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 5))
      let savedRows = app.buttons.matching(
        NSPredicate(format: "identifier BEGINSWITH 'saved-day-'"))
      XCTAssertEqual(savedRows.count, 0)
      XCTAssertFalse(app.buttons["Open selected day"].exists)
      XCTAssertTrue(dayButton.isSelected)
      dayButton.tap()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 5))
      XCTAssertTrue(app.staticTexts[dateLabel].exists)
      back.tap()
      app.buttons["Today"].tap()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 5))
      back.tap()
      app.buttons["Today"].tap()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 5))

      app.buttons["new-task"].tap()
      let field = app.descendants(matching: .any).matching(identifier: "task-title").firstMatch
      XCTAssertTrue(field.waitForExistence(timeout: 5))
      field.tap()
      field.typeText("Saved plan")
      app.buttons["Save"].tap()
      back.tap()
      XCTAssertTrue(savedRows.firstMatch.waitForExistence(timeout: 5))
      XCTAssertEqual(savedRows.count, 1)
    }
  #endif

  func testAddCompleteAndPreviewExport() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    #if os(macOS)
      if !app.windows.firstMatch.waitForExistence(timeout: 2) {
        app.menuBars.menuBarItems["File"].click()
        app.menuItems["New Window"].click()
      }
    #endif
    let addButton = app.buttons["new-task"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 10))
    activate(addButton)
    let field = app.descendants(matching: .any).matching(identifier: "task-title").firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    activate(field)
    field.typeText("Read a book")
    activate(app.buttons["Save"])
    let completion = app.buttons["task-completion-Read a book"]
    XCTAssertTrue(completion.waitForExistence(timeout: 5))
    activate(completion)
    #if os(iOS)
      if app.segmentedControls.buttons["Markdown"].exists {
        app.segmentedControls.buttons["Markdown"].tap()
      }
    #endif
    let editor = app.textViews["markdown-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 5))
    XCTAssertTrue((editor.value as? String)?.contains("- [x] Read a book") == true)
    activate(app.buttons["export-image"])
    XCTAssertTrue(app.buttons["Save PNG"].waitForExistence(timeout: 5))
    let enabled = NSPredicate(format: "enabled == true")
    expectation(for: enabled, evaluatedWith: app.buttons["Save PNG"])
    waitForExpectations(timeout: 10)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Dayframe export"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  func testSamplePlanWithLargeText() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--sample-plan", "-AppleLanguages", "(ja)",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 10))
    let completion = app.buttons["task-completion-Morning routine"]
    XCTAssertTrue(completion.waitForExistence(timeout: 5))
    #if os(iOS)
      for _ in 0..<4 where !completion.isHittable { app.swipeUp() }
    #endif
    XCTAssertTrue(completion.isHittable)
    activate(completion)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Dayframe Japanese Dynamic Type"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func activate(_ element: XCUIElement) {
    #if os(macOS)
      element.click()
    #else
      element.tap()
    #endif
  }
}
