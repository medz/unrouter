# Changelog

## 0.2.0

### Highlights

Cleans up the metadata API, fixes a history queue bug, and upgrades the
underlying path-matching engine to roux 1.0.0.

### Breaking Changes

- `RouteNode.meta` and `RouteRecord.meta` are now `Map<String, Object?>` instead
  of `Map<String, Object?>?`. Both default to `const {}`. Callers that passed
  `meta: null` or guarded against `meta == null` must be updated.
- `Unrouter.aliases` and `Unrouter.matcher` expose `roux.Router<T>`, which no
  longer has a `.match()` method. Use `.find()` instead.

### What's New

- Upgrade roux to 1.0.0. The router now uses `.find()` for path lookups and
  per-entry `.add()` for route registration, matching the roux 1.0.0 API.
  Path matching remains case-sensitive.

### Migration Notes

- Replace any direct calls to `router.matcher.match(path)` or
  `router.aliases.match(path)` with `.find(path)`.
- Remove `?? const {}` guards on `RouteNode.meta` and `RouteRecord.meta` — the
  value is always a non-null map.

## 0.1.0

- Initial shared routing core package split from the Unrouter workspace.
- Added history-backed navigation, route matching, named routes, guards, route
  params, query helpers, and merged route metadata support.
