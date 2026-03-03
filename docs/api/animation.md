# Animation

## spring() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Returns a new source with a value always moving torwards the input source value.

- **Type**

    ```luau
    function spring<T>(
        source: () -> T & Animatable,
        period: number = 1,
        damping_ratio: number = 1
    ): (() -> T, SpringControl<T>)

    type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3 | Rect

    type SpringControl<T> = ({
        position: T?,
        velocity: T?,
        impulse: T?
    }) -> ()
    ```

- **Details**

    Creates a reactive scope internally to detect source updates.

    The movement is physically simulated according to a
    [spring](https://en.wikipedia.org/wiki/Simple_harmonic_motion).

    `period` is the amount of time in seconds it takes for the spring to
    complete one full cycle if undamped.

    `damping_ratio` is the amount of resistance applied to the spring.

    - \>1 = Overdamped - slowly reaches target without any overshoot.
    - 1 = Critically damped - reaches target without any overshoot.
    - <1 = Underdamped - reaches target with some overshoot.
    - 0 = Undamped - never stabilizes, oscillates forever.

    By default, the spring solver is ran at 120 Hz in
    [`Heartbeat`](https://create.roblox.com/docs/reference/engine/classes/RunService#Heartbeat).
    You can change when the solver runs by calling `vide.step(dt)`, which will
    advance the simulation time by `dt` seconds and automatically stop the
    solver running in heartbeat.

    ::: warning
    Large periods or damping ratios can break the spring.
    :::

  # tween

A small TweenService wrapper that provides ergonomic tweening helpers and optional presets.

This module is designed for UI animations (size, position, transparency, colour, etc.). It is safe to `require` in non-Roblox environments (it should fall back to applying goals instantly).

## Exports

- `vide.tween.tweenTo(instance, goals, tweenInfo?) -> Tween?`
- `vide.tween.tween(goals, tweenInfo?) -> Action` (optional, if you implemented the Action form)
- `vide.tween.presets` (optional)

## tweenTo()

Tweens an instance to a set of goal properties.

### Type

```lua
tweenTo(instance: Instance, goals: { [string]: any }, tweenInfo: TweenInfo?) -> Tween?
