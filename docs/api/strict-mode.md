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

1. Run reactive scopes twice when a source updates.
2. Throw an error if yields occur where they are not allowed.
3. Checks for `indexes()` and `values()` outputting primitive values.
4. Checks for `values()` input having duplicate values.
5. Checks for duplicate nested properties at same depth.
6. Checks for destruction of an active scope.
7. Better error reporting and stack traces + creation traces of property bindings.

By rerunning reactive scopes twice each time they update, it helps ensure that
computations are pure, and that any cleanup is done correctly.

Accidental yielding within reactive scopes can break Vide's reactive graph,
which strict mode will catch.

As well as additional safety checks, Vide will dedicate extra resources to
recording and better emitting stack traces where errors occur, particularly
when implicit effects are created for instance property updating.

It is recommended to develop UI with strict mode and to disable it when pushing to
production. In Roblox, production code compiles at O2 by default, so you do not
need to worry about disabling strict mode unless you have manually enabled it.
