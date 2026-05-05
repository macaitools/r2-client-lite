# R2Desk Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a native macOS S3/R2 file manager app with local storage, multi-bucket support, basic file operations, CI packaging, screenshots, and English/Chinese localization.

**Architecture:** A Swift package contains a SwiftUI macOS executable target and a small core library. The app uses direct S3-compatible REST requests with AWS Signature Version 4, stores public config in JSON, stores secrets in Keychain, and packages an ad-hoc signed `.app` from CI.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation URLSession, Security Keychain, XCTest, GitHub Actions on macOS.

---

### Task 1: Create Swift Package And Core Tests

**Files:**
- Create: `Package.swift`
- Create: `Tests/R2DeskCoreTests/R2DeskCoreTests.swift`
- Create: `Sources/R2DeskCore/*.swift`

**Steps:**
1. Add a Swift package with `R2Desk` executable and `R2DeskCore` library.
2. Write failing XCTest cases for byte formatting, config round-trip, and S3 request URL/signing helpers.
3. Implement the minimum core code to pass.
4. Run `swift test`.

### Task 2: Build Native macOS App

**Files:**
- Create: `Sources/R2Desk/R2DeskApp.swift`
- Create: `Sources/R2Desk/ContentView.swift`
- Create: `Sources/R2Desk/AppState.swift`
- Create: `Sources/R2Desk/Localizable.strings`

**Steps:**
1. Add the SwiftUI app entry point.
2. Add sidebar, object table, toolbar, bucket settings sheet, delete confirmation, and empty/error states.
3. Wire UI actions to core storage and S3 client APIs.
4. Run `swift build`.

### Task 3: Add Packaging And CI

**Files:**
- Create: `scripts/package_app.sh`
- Create: `.github/workflows/build-macos.yml`
- Create: `Sources/R2Desk/Resources/Info.plist`

**Steps:**
1. Build release executable.
2. Create `.app` bundle and copy executable/resources.
3. Ad-hoc sign with `codesign --force --deep --sign -`.
4. Zip the app as a CI artifact.

### Task 4: Add Screenshots And README

**Files:**
- Create: `scripts/render_screenshots.mjs`
- Create: `screens/*.png`
- Create: `README.md`

**Steps:**
1. Generate screenshots for bucket list, add bucket, upload flow, delete confirmation, and settings.
2. Document features, R2 setup, local data storage, CI packaging, and unsigned app opening.
3. Run final verification commands.
