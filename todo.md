# todo

- better error reporting and stack traces in strict mode
- auto-enable of strict mode depending on compiler optimizaton level
- investigate if weak table iteration can be invalidated
- have reactive recomputations track sources dynamically?
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
