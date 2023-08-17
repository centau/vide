# todo

- cleanup codebase
- way to optionally cleanup `values()` and `indexes()` when they gc
- limit `cleanup()` call to once per function scope?
- better error reporting and stack traces in strict mode
- auto-enable of strict mode depending on compiler optimizaton level
- check smoothness of spring at high frequency updates
- review alternative to nested properties, merge function
- implement from solid
  - [x] onCleanup > `cleanup()`
  - [x] Index > `indexes()`
  - [x] For > `values()`
  - [ ] untrack
  - [ ] batch
  - [ ] async/resource/loading/suspense
  - [ ] stores
    - solid stores seem impossible to implement in Luau, seek alternative
