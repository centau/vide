# Animation

## spring() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Returns a new source with a value always moving torwards the input source value.

- **Type**

    ```luau
    function spring<T>(
        source: () -> T & Animatable,
        period: number = 1,
        damping_ratio: number = 1
    ): () -> T

    type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3 | Rect
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
