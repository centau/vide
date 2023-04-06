# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

---

## [0.4.0] - 2023-01-26

### Added

- Component grouping and `Registry:group()`.
- Method `View:use()`.
- Constant `ecr.null`.

### Removed

- Method `View:include()` and `Observer:include()`.

### Fixed

- `Registry:add()` not firing `Registry:added()` signals.
- Mismatch between argument list and values returned in multi-typed observers.
- Observers not garbage collecting after calling `Observer:disconnect()`.

### Improved

- Connection firing speed by ~70%.

---

## [0.3.0] - 2023-01-09

### Added

- Overload for `Registry:create()` to create an entity with a given identifier.

### Changed

- Registry signals no longer pass the registry as the first argument to listeners.
- Observers no longer track entities with removed components.
- Method `Registry:entities()` now creates and returns an array of only valid entities.
- Function `ecr.registry()` can no longer pre-allocate memory.

### Removed

- Method `Registry:capacity()`.

### Improved

- Double-type view iteration speed by ~100%.

---

## [0.2.0] - 2022-12-08

### Added

- Method `View:include()` and `Observer:include()`.
- Method `Registry:patch()`.
- Method `Registry:add()` and optional default parameter for `ecr.component()`.

### Changed

- Behavior `for ... in View do` now behaves the same as `for ... in View:each() do`.
- Signal diconnect API (Signal now returns a connection object to call disconnect on).

### Improved

- Entity creation and release speed by ~100%.
- Multi-type view iteration speed by ~60%.

## [0.1.0] - 2022-11-16

- Initial release
