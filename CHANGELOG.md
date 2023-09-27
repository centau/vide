# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## Unreleased

### Added

- `cleanup()` accepts objects with a `Destroy()` or `Disconnect()` interface.
- `read()` as a utility to read sources or passthrough a non-source value.

### Changed

- Reactive scopes created within reactive scopes are now destroyed on rerun.
- `untrack()` can be called outside of reactive scopes.

### Fixed

- `show()` and `switch()` not updating when in strict mode.

--------------------------------------------------------------------------------

## [0.1.0] - 2023-09-20

- Initial release
