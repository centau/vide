# Strict Mode

Strict mode is library-wide and can get set by doing:

```luau
vide.strict = true
```

It is automatically enabled when Vide is first required and not running in O2
optimization level.

Strict mode is designed to help the development process by adding safety checks
and identifying improper usage.

Currently, strict mode will:

1. Run derived sources twice a source updates.
2. Run effects twice when a source updates.
3. Throw an error if yields occur where they are not allowed.
4. Checks for `indexes()` and `values()` returning primitive values.
5. Checks for `values()` input having duplicate values.
6. Checks for duplicate nested properties at same depth.
7. Better error reporting and stack traces + creation traces of property bindings.

By rerunning derived sources and effects twice each time they update, it helps
ensure that derived source computations are pure, and that any
cleanups made in derived sources or effects are done correctly.

Accidental yielding within reactive scopes can break Vide's reactive graph,
which strict mode will catch.

As well as additional safety checks, Vide will dedicate extra resources to
recording and better emitting stack traces where errors occur, particularly
when binding properties to sources.

It is recommended to develop UI with strict mode and to disable it when pushing to
production. In Roblox, production code compiles at O2 by default, so you don't
need to worry about disabling strict mode unless you have manually enabled it.
