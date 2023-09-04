# todo

- better error reporting and stack traces in strict mode
- auto-enable of strict mode depending on compiler optimizaton level
- investigate if weak table iteration can be invalidated
- have derived sources/bindings track sources dynamically?
  - solves case where sources are used in if-branching guarded by another
    source
  - significantly reduces performance
- solution to component cleanup
  - rely on `Instance.Destroying` event and manual destruction when cleanup is
    needed?
  - expand behavior of `vide.cleanup()` to detect garbage collection of
    arbitrary values, not needing manual destruction
- solution to nested reactivity, see: SolidJS stores
- SolidJS control flow components
  - Show
  - Switch
  - Dynamic
  - Portal
- batch source updates
