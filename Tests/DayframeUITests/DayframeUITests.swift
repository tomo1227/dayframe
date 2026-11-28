import CoreImage
import XCTest

@MainActor
final class DayframeUITests: XCTestCase {
  #if os(iOS)
    func testAppearanceMenuSwitchesBetweenLightAndDark() throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()
      XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 10))

      let overflow = app.buttons["TopOverflowBarButtonItem"]
      let appearance = app.buttons["Appearance"]
      for (label, expected) in [("Light", 255), ("Dark", 0)] {
        overflow.tap()
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))
        appearance.tap()
        let option = app.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        XCTAssertTrue(option.waitForNonExistence(timeout: 5))
        let brightness = try backgroundBrightness(in: app.screenshot())
        XCTAssertEqual(brightness, expected, accuracy: 55, label)
      }
    }

    private func backgroundBrightness(in screenshot: XCUIScreenshot) throws -> Int {
      let image = try XCTUnwrap(CIImage(data: screenshot.pngRepresentation))
      let extent = image.extent
      let sample = extent.insetBy(dx: extent.width * 0.14, dy: extent.height * 0.25)
      let averaged = image.applyingFilter(
        "CIAreaAverage", parameters: ["inputExtent": CIVector(cgRect: sample)])
      let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
      var pixel = [UInt8](repeating: 0, count: 4)
      pixel.withUnsafeMutableBytes { buffer in
        guard let address = buffer.baseAddress else { return }
        CIContext().render(
          averaged, toBitmap: address, rowBytes: 4,
          bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: colorSpace)
      }
      return pixel.prefix(3).map(Int.init).reduce(0, +) / 3
    }

    func testMarkdownRestoresMissingDateHeadingAboveExistingPlan() throws {
      let app = XCUIApplication()
      app.launchArguments = [
        "--ui-testing", "--headerless-plan", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
      ]
      app.launch()

      let markdown = app.segmentedControls.buttons["Markdown"]
      XCTAssertTrue(markdown.waitForExistence(timeout: 10))
      markdown.tap()
      let editor = app.textViews["markdown-editor"]
      XCTAssertTrue(editor.waitForExistence(timeout: 5))
      let today = Date.now.formatted(
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
      let value = try XCTUnwrap(editor.value as? String)
      XCTAssertTrue(value.hasPrefix("# \(today)\n\n- [ ] Pack lunch"), value)

      app.segmentedControls.buttons["Plan"].tap()
      XCTAssertTrue(app.buttons["task-completion-Pack lunch"].waitForExistence(timeout: 5))
    }

    func testMarkdownKeyboardInsertsSingleFenceAndSymbolsAtCursor() throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()

      let markdown = app.segmentedControls.buttons["Markdown"]
      XCTAssertTrue(markdown.waitForExistence(timeout: 10))
      markdown.tap()
      let editor = app.textViews["markdown-editor"]
      XCTAssertTrue(editor.waitForExistence(timeout: 5))
      let heading = app.buttons["markdown-insert-heading"]
      XCTAssertFalse(heading.exists)

      editor.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.75)).tap()
      XCTAssertTrue(heading.waitForExistence(timeout: 5))
      editor.typeText("\n")
      heading.tap()
      editor.typeText("Notes\n")
      app.buttons["markdown-insert-subheading"].tap()
      editor.typeText("Example\n")
      editor.typeText("Pack lunch")
      app.buttons["markdown-make-checklist"].tap()
      editor.typeText("\n")
      app.buttons["markdown-insert-backtick"].tap()
      editor.typeText("inline")
      app.buttons["markdown-insert-backtick"].tap()
      editor.typeText("\n")
      app.buttons["markdown-insert-fence"].tap()
      app.buttons["markdown-insert-asterisk"].tap()
      editor.typeText("続き")

      let value = try XCTUnwrap(editor.value as? String)
      let expected = "\n# Notes\n## Example\n- [ ] Pack lunch\n`inline`\n```*続き"
      XCTAssertTrue(value.hasPrefix("# "), value)
      XCTAssertTrue(value.contains(expected), value)
      XCTAssertEqual(value.components(separatedBy: "```").count, 2)
      app.segmentedControls.buttons["Plan"].tap()
      XCTAssertTrue(heading.waitForNonExistence(timeout: 5))
    }

    func testNewPlanUsesPreferredTemplateAndExportHasIndependentSizeControls() {
      let app = XCUIApplication()
      app.launchArguments = [
        "--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
        "-newPlanTemplate", "daily",
      ]
      app.launch()
      let markdown = app.segmentedControls.buttons["Markdown"]
      XCTAssertTrue(markdown.waitForExistence(timeout: 10))
      markdown.tap()
      let editor = app.textViews["markdown-editor"]
      XCTAssertTrue(editor.waitForExistence(timeout: 5))
      let templateBody = "## Morning\n\n## Afternoon\n\n## Evening"
      XCTAssertTrue((editor.value as? String)?.contains(templateBody) == true)
      app.buttons["export-image"].tap()
      let taskSize = app.sliders["story-task-text-size"]
      let dateSize = app.sliders["story-date-heading-size"]
      XCTAssertTrue(taskSize.waitForExistence(timeout: 5))
      for _ in 0..<5 where !dateSize.isHittable { app.swipeUp() }
      XCTAssertTrue(taskSize.isHittable)
      XCTAssertTrue(dateSize.isHittable)
      let initialDateSize = dateSize.value as? String
      taskSize.adjust(toNormalizedSliderPosition: 1)
      XCTAssertEqual(taskSize.value as? String, "175%")
      XCTAssertEqual(dateSize.value as? String, initialDateSize)
      dateSize.adjust(toNormalizedSliderPosition: 1)
      XCTAssertEqual(dateSize.value as? String, "150%")
    }

    func testMarkdownShortcutsInsertDatesAndTaskSyntax() throws {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()
      let markdown = app.segmentedControls.buttons["Markdown"]
      XCTAssertTrue(markdown.waitForExistence(timeout: 10))
      markdown.tap()

      let editor = app.textViews["markdown-editor"]
      XCTAssertTrue(editor.waitForExistence(timeout: 5))
      let original = try XCTUnwrap(editor.value as? String)
      let heading = try XCTUnwrap(original.split(separator: "\n").first)
      let planDate = heading.dropFirst(2)
      let today = Date.now.formatted(
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day())

      editor.tap()
      editor.typeText("\nDates: ")
      let shortcuts = app.descendants(matching: .any).matching(
        identifier: "markdown-shortcuts"
      ).firstMatch
      tapMarkdownShortcut("markdown-insert-today", in: app, menu: shortcuts)
      editor.typeText(" / ")
      tapMarkdownShortcut("markdown-insert-plan-date", in: app, menu: shortcuts)
      editor.typeText("\n")
      tapMarkdownShortcut("markdown-insert-task", in: app, menu: shortcuts)
      editor.typeText("Pack lunch\n")
      tapMarkdownShortcut("markdown-insert-note", in: app, menu: shortcuts)
      editor.typeText("Use the small bag")

      let value = try XCTUnwrap(editor.value as? String)
      let expected = "Dates: \(today) / \(planDate)\n- [ ] Pack lunch\n@note Use the small bag"
      XCTAssertTrue(value.contains(expected), value)
    }

    private func tapMarkdownShortcut(_ id: String, in app: XCUIApplication, menu: XCUIElement) {
      XCTAssertTrue(menu.wait(for: \.isHittable, toEqual: true, timeout: 5))
      menu.tap()
      let item = app.buttons[id]
      XCTAssertTrue(item.wait(for: \.isHittable, toEqual: true, timeout: 5))
      item.tap()
      XCTAssertTrue(item.waitForNonExistence(timeout: 5))
    }

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

  #if os(iOS)
    func testAddTaskWithTimeWheel() {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
      app.launch()
      let addButton = app.buttons["new-task"]
      XCTAssertTrue(addButton.waitForExistence(timeout: 10))
      addButton.tap()
      let title = app.descendants(matching: .any).matching(identifier: "task-title").firstMatch
      XCTAssertTrue(title.waitForExistence(timeout: 5))
      XCTAssertFalse(app.pickerWheels.firstMatch.exists)
      app.switches["task-set-time"].switches.firstMatch.tap()
      let minutes = app.pickerWheels.element(boundBy: 1)
      XCTAssertTrue(minutes.waitForExistence(timeout: 5))
      minutes.swipeUp(velocity: .slow)

      title.tap()
      title.typeText("Timed task")
      app.buttons["Save"].tap()
      if app.segmentedControls.buttons["Markdown"].exists {
        app.segmentedControls.buttons["Markdown"].tap()
      }
      let editor = app.textViews["markdown-editor"]
      XCTAssertTrue(editor.waitForExistence(timeout: 5))
      let markdown = editor.value as? String ?? ""
      XCTAssertNotNil(markdown.range(of: #"09:(?!00)[0-5][0-9] Timed task"#, options: .regularExpression))
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
