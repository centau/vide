# todo

- cleanup codebase
- better error reporting and stack traces in strict mode
- auto-enable of strict mode depending on compiler optimizaton level
- check smoothness of spring at high frequency updates
- have reactive recomputations track sources dynamically
  - addresses case where sources are used in if-branching guarded by another
    source
  - performance implications
- implement from solid
  - [x] onCleanup > `cleanup()`
  - [x] Index > `indexes()`
  - [x] For > `values()`
  - [x] untrack
  - [ ] batch
  - [ ] async/resource/loading/suspense
  - [ ] stores
