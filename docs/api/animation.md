# Animation API

## spring()

Returns a new state with a dynamically animated value of the source.

- ### Type

    ```lua
    type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3
    
    function spring<T>(
        source: () -> T & Animatable,
        period: number = 1,
        damping_ratio: number = 1
    ): () -> T
    ```

- ### Details

    The output state value is updated every frame based on the source state
    value.

    The change is physically simulated according to a
    [spring](https://en.wikipedia.org/wiki/Simple_harmonic_motion).

    `period` is the amount of time in seconds it takes for the spring to
    complete one full oscillation.

    `damping_ratio` is the amount of resistance applied to the spring.

    - \>1 = Overdamped (not currently supported).
    - 1 = Critically damped - reaches target without any overshoot.
    - <1 = Underdamped - reaches target with some overshoot.
    - 0 = Undamped - never stabilizes, oscillates forever.

    Velocity is conserved between source state updates for smooth animation.

--------------------------------------------------------------------------------
