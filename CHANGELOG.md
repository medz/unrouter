## 0.3.0

### Features

- **Navigator 1.0 compatibility**: added `enableNavigator1` (default `true`) so APIs like `showDialog`, `showModalBottomSheet`, `showMenu`, and `Navigator.push/pop` work when using `Unrouter`.
- **Example updates**: the example app now demonstrates Navigator 1.0 APIs alongside existing routing patterns.

### Improvements

- `popRoute` now delegates to the embedded Navigator first (when enabled) before falling back to history navigation.
- Relative navigation now normalizes dot segments (`.` / `..`) and clamps above-root paths.

### Testing

- Added comprehensive widget tests covering Navigator 1.0 overlays, push/pop/popUntil, and nested Navigator behavior.
- Added tests for relative navigation dot-segment normalization.

## 0.2.0

### Breaking Changes

- **Navigation API refactored**: History navigation methods (`back()`, `forward()`, `go()`) are now accessed through `navigate` property
  - Before: `router.back()`
  - After: `router.navigate.back()`
- **Internal reorganization**: Removed `router_delegate.dart` file. The `Navigate` interface and router delegate logic have been consolidated into `router.dart`

### Features

- **Link widget**: Added declarative navigation with the new `Link` widget (#5)
  - Simple usage: `Link(to: Uri.parse('/about'), child: Text('About'))`
  - Advanced usage: `Link.builder` for custom gesture handling
  - Supports `replace` and `state` parameters
  - Automatic mouse cursor (click) and accessibility semantics (link role)
  - Example: Build navigation links without imperative callbacks
- **BuildContext extensions**: Added convenient extensions for navigation (#6)
  - Use `context.navigate` to access navigation methods from any widget
  - Use `context.router` to access the router instance
  - Example: `context.navigate(.parse('/about'))`
- **Better error messages**: `Navigate.of()` now throws helpful `FlutterError` with clear messages when:
  - Called outside a Router scope
  - Router delegate doesn't implement `Navigate`

### Improvements

- Changed `matchRoutes` parameter type from `List<Inlet>` to `Iterable<Inlet>` for better flexibility
- Updated examples to demonstrate new BuildContext extension usage
- Added comprehensive tests for context navigation features

### Migration Guide

Update your navigation code to use the new API:

```dart
// Before
router.back()
router.forward()
router.go(-1)

// After
router.navigate.back()
router.navigate.forward()
router.navigate.go(-1)

// Or use the new BuildContext extension
context.navigate.back()
```

## 0.1.1

- Update package description and add pub topics
- Remove routingkit dependency and format product card
- Format Dart code with dart format
