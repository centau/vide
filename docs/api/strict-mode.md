# Strict Mode

Strict mode is library-wide and can get set by doing:

```lua
vide.strict = true
```

Strict mode is designed to help the development process by adding safety checks
and identifying improper usage.

Currently, strict mode will:

1. Run derived sources twice a source updates.
2. Run watchers twice when a source updates.
3. Throw an error if yields occur where they are not allowed.
4. Checks for `indexes()` and `values()` returning primitive values.
5. Better error reporting and stack traces.

By rerunning sources and watchers, any side-effects are made more apparent.
This also helps ensure that cleanups are being handled correctly.

Accidental yielding within reactive scopes can break Vide's reactive graph,
which strict mode can catch.

As well as additional safety checks, Vide will dedicate extra resources to
recording and better emitting stack traces where errors occur, particularly
when binding properties to sources.

It is recommend to develop UI with strict mode and to disable it when pushing to
production.
