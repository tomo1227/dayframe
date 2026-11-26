.DEFAULT_GOAL := build

CONFIGURATION ?= debug
SWIFT_PATHS ?= Package.swift Sources Tests Tools
APP := .build/Dayframe.app
SIGN_IDENTITY ?= -
.PHONY: build test run lint complex format fmt icons apm_ci apm_audit

build: icons
	swift build --configuration $(CONFIGURATION)
	mkdir -p "$(APP)/Contents/MacOS" "$(APP)/Contents/Resources"
	cp dayframe/Info.plist "$(APP)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Dayframe' "$(APP)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier app.dayframe.Dayframe' "$(APP)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c 'Set :DayframeCloudContainer ""' "$(APP)/Contents/Info.plist"
	cp -R Resources/en.lproj Resources/ja.lproj Resources/Example.md "$(APP)/Contents/Resources/"
	cp .build/Dayframe.icns "$(APP)/Contents/Resources/Dayframe.icns"
	/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string Dayframe.icns' "$(APP)/Contents/Info.plist"
	cp "$$(swift build --configuration $(CONFIGURATION) --show-bin-path)/DayframeDesktop" "$(APP)/Contents/MacOS/Dayframe"
	codesign --force --sign "$(SIGN_IDENTITY)" --entitlements dayframe/Local.entitlements "$(APP)"

icons:
	swift Tools/GenerateIcon.swift
	iconutil --convert icns .build/Dayframe.iconset --output .build/Dayframe.icns

test:
	swift test

run: build
	open "$(APP)"

lint:
	xcrun swift-format lint --strict --recursive $(SWIFT_PATHS)

complex:
	swiftlint lint --config .swiftlint.yml $(SWIFT_PATHS)

fmt format:
	xcrun swift-format format --in-place --recursive $(SWIFT_PATHS)

apm_ci:
	apm install --policy ./apm-policy.yml --frozen

apm_audit:
	apm audit --ci --policy ./apm-policy.yml
