# Animation API

## spring()

Returns a new source with a dynamically animated value of the input source.

- **Type**

    ```lua
    function spring<T>(
        source: () -> T & Animatable,
        period: number = 1,
        damping_ratio: number = 1
    ): () -> T

    type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3
    ```

- **Details**

    The output source value is updated every frame based on the input source
    value.

    The output is physically simulated according to a
    [spring](https://en.wikipedia.org/wiki/Simple_harmonic_motion).

    `period` is the amount of time in seconds it takes for the spring to
    complete one full oscillation.

    `damping_ratio` is the amount of resistance applied to the spring.

    - \>1 = Overdamped (not currently supported).
    - 1 = Critically damped - reaches target without any overshoot.
    - <1 = Underdamped - reaches target with some overshoot.
    - 0 = Undamped - never stabilizes, oscillates forever.

    Velocity is conserved between source updates for smooth animation.
