# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## [Unreleased]

### Added

- `create("ClassName", { props })` and `create(Instance, { props })` syntax.

--------------------------------------------------------------------------------

## [0.3.1] - 2024-10-09

### Added

- Context functions now also return results.
- `version` table with current version.

--------------------------------------------------------------------------------

## [0.3.0] - 2024-10-06

### Added

- `context()`.

### Changed

- `root()` now returns its destructor as the first value by default.

### Fixed

- Error stack traces being lost.
- `root()` now destroys the scope automatically if an error occurs during call.

--------------------------------------------------------------------------------

## [0.2.0] - 2023-11-22

### Added

- Batched updates with `batch()`.

### Changed

- Improved graph updating algorithm.
- Graph nodes when destroyed no longer destroy children; only owned.

### Fixed

- Graph edge case where a destroyed node can be readded if it was queued for
  rerun before being destroyed.
- Some properties not being applied when `create()` is used recursively.

--------------------------------------------------------------------------------

## [0.1.1] - 2023-09-30

### Added

- `cleanup()` accepts objects with a `Destroy()` or `Disconnect()` interface.
- `read()` as a utility to read sources or passthrough a non-source value.

### Changed

- Reactive scopes created within reactive scopes are now destroyed on rerun.
- `untrack()` can be called outside of reactive scopes.
- `changed()` will also run its callback with the initial property value.

### Fixed

- `show()` and `switch()` not updating when in strict mode.

--------------------------------------------------------------------------------

## [0.1.0] - 2023-09-20

- Initial release
