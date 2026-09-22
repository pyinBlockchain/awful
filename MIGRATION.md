# Migration to Xcode 16+ (iOS 17+)

The app is currently built with Xcode 14.2 / Swift 5.7 / iOS 16 because the dev Mac is capped
at macOS 12 (see CLAUDE.md §10). When we move to a Mac with Xcode 16 or later, do these steps
in order, building and running all tests after each.

## 1. Project settings (`project.yml`)
- `deploymentTarget.iOS`: `16.0` → `17.0`.
- Keep `SWIFT_VERSION: 5.0` for the first build; then try `6.0` (strict concurrency) and fix warnings.
- Replace the `ar.lproj`/`en.lproj` string resources with `Localizable.xcstrings` (step 3).
- Update `xcodeVersion` if set, then regenerate with `xcodegen generate`.
- Homebrew can install XcodeGen normally again (`brew install xcodegen`).

## 2. Observation
- `final class X: ObservableObject` with `@Published var` → `@Observable final class X` with plain `var`.
- `@StateObject` → `@State`; `@ObservedObject` → plain `let`/`var` (or `@Bindable` when binding);
  `@EnvironmentObject` → `@Environment(X.self)`; `.environmentObject(x)` → `.environment(x)`.
- Remove `import Combine` where only used for `@Published`.

## 3. Strings
- In Xcode: select `Localizable.strings` → Editor → "Migrate to String Catalog".
  Confirm both `ar` and `en` columns are 100% translated, then delete the `.lproj` string files.

## 4. Persistence
- Optional: move `FavoritesStore` from `UserDefaults` to SwiftData. Keep the same protocol so
  view models don't change. Migrate existing favorite IDs on first launch.

## 5. APIs to modernize
- Map: `Map(coordinateRegion:annotationItems:)` → iOS 17 `Map(position:) { Annotation … }`
  with `MapCameraPosition`; move `region` out of `@State` hacks; consider pin clustering and
  raising the selected pin.
- Remove the RTL workarounds once verified fixed: `FilterBarView.chipRow` (horizontal ScrollView
  opening at the wrong end) and the Favorites `List` avoidance (mirrored swipe rows).
- `.onChange(of:perform:)` → `.onChange(of:) { old, new in }`.
- Custom empty-state view → optionally `ContentUnavailableView` (keep our Arabic copy).
- `PreviewProvider` structs → `#Preview`.
- Code written without `if`/`switch` expressions may be simplified (optional, not required).

## 6. Release
- App Store submissions must use the current required Xcode/SDK; confirm on
  developer.apple.com before the first upload.
