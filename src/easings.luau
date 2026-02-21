--!native
--!optimize 2

export type EasingFunction = (t: number) -> number

local function lerp(t: number): number
    return t
end

local function sine_ease_in(t: number): number
    return 1 - math.cos((math.pi * t) / 2)
end

local function sine_ease_out(t: number): number
    return math.sin((math.pi * t) / 2)
end

local function sine_ease_inout(t: number): number
    return -(math.cos(math.pi * t) - 1) / 2
end

local function quad_ease_in(t: number): number
    return t^2
end

local function quad_ease_out(t: number): number
    return 1 - (1 - t)^2
end

local function quad_ease_inout(t: number): number
    return if t < 0.5 then 2 * t^2 else 1 - math.pow(-2 * t + 2, 2) / 2
end

local function cubic_ease_in(t: number): number
    return t^3
end

local function cubic_ease_out(t: number): number
    return 1 - math.pow(1 - t, 3);
end

local function cubic_ease_inout(t: number): number
    return if t < 0.5 then 4 * t^3 else 1 - math.pow(-2 * t + 2, 3) / 2
end

local function quart_ease_in(t: number): number
    return t^4
end

local function quart_ease_out(t: number): number
    return 1 - math.pow(1 - t, 4)
end

local function quart_ease_inout(t: number): number
    return if t < 0.5 then 8 * t^4 else 1 - math.pow(-2 * t + 2, 4) / 2
end

local function quint_ease_in(t: number): number
    return t^5
end

local function quint_ease_out(t: number): number
    return 1 - math.pow(1 - t, 5)
end

local function quint_ease_inout(t: number): number
    return if t < 0.5 then 16 * t^5 else 1 - math.pow(-2 * t + 2, 5) / 2
end

local function expo_ease_in(t: number): number
    return if t == 0 then 0 else math.pow(2, 10 * t - 10)
end

local function expo_ease_out(t: number): number
    return if t == 1 then 1 else 1 - math.pow(2, -10 * t)
end

local function expo_ease_inout(t: number): number
    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    end

    return if t < 0.5
        then math.pow(2, 20 * t - 10) / 2
        else (2 - math.pow(2, -20 * t + 10)) / 2
end

local function circ_ease_in(t: number): number
    return 1 - math.sqrt(1 - math.pow(t, 2))
end

local function circ_ease_out(t: number): number
    return math.sqrt(1 - math.pow(t - 1, 2))
end

local function circ_ease_inout(t: number): number
    return if t < 0.5
        then (1 - math.sqrt(1 - math.pow(2 * t, 2))) / 2
        else (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) / 2
end

local _BACK_C1 = 1.70158
local _BACK_C2 = _BACK_C1 * 1.525
local _BACK_C3 = _BACK_C1 + 1
local function back_ease_in(t: number): number
    return _BACK_C3 * t^3 - _BACK_C1 * t^2
end

local function back_ease_out(t: number): number
    return 1 + _BACK_C3 * math.pow(t - 1, 3) + _BACK_C1 * math.pow(t - 1, 2)
end

local function back_ease_inout(t: number): number
    return if t < 0.5
        then (math.pow(2 * t, 2) * ((_BACK_C2 + 1) * 2 * t - _BACK_C2)) / 2
        else (math.pow(2 * t - 2, 2) * ((_BACK_C2 + 1) * (t * 2 - 2) + _BACK_C2) + 2) / 2
end

local _ELASTIC_C4 = (2 * math.pi) / 3
local _ELASTIC_C5 = (2 * math.pi) / 4.5
local function elastic_ease_in(t: number): number
    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    end

    return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * _ELASTIC_C4)
end

local function elastic_ease_out(t: number): number
    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    end

    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * _ELASTIC_C4) + 1
end

local function elastic_ease_inout(t: number): number
    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    end

    return if t < 0.5
        then -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * _ELASTIC_C5)) / 2
        else (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * _ELASTIC_C5)) / 2 + 1
end

local _BOUNCE_N1 = 7.5625
local _BOUNCE_D1 = 2.75
local function bounce_ease_out(t: number): number
    if t < (1 / _BOUNCE_D1) then
        return _BOUNCE_N1 * t^2
    elseif t < (2 / _BOUNCE_D1) then
        return _BOUNCE_N1 * (t - (1.5 / _BOUNCE_D1))^2 + 0.75
    elseif t < (2.5 / _BOUNCE_D1) then
        return _BOUNCE_N1 * (t - (2.25 / _BOUNCE_D1))^2 + 0.9375
    else
        return _BOUNCE_N1 * (t - (2.625 / _BOUNCE_D1))^2 + 0.984375
    end
end

local function bounce_ease_in(t: number): number
    return 1 - bounce_ease_out(1 - t)
end

local function bounce_ease_inout(t: number): number
    return if t < 0.5
        then (1 - bounce_ease_out(1 - 2 * t)) / 2
        else (1 + bounce_ease_out(2 * t - 1)) / 2
end

local easings = {
    lerp = lerp,
    sine_ease_in = sine_ease_in,
    sine_ease_out = sine_ease_out,
    sine_ease_inout = sine_ease_inout,
    quad_ease_in = quad_ease_in,
    quad_ease_out = quad_ease_out,
    quad_ease_inout = quad_ease_inout,
    cubic_ease_in = cubic_ease_in,
    cubic_ease_out = cubic_ease_out,
    cubic_ease_inout = cubic_ease_inout,
    quart_ease_in = quart_ease_in,
    quart_ease_out = quart_ease_out,
    quart_ease_inout = quart_ease_inout,
    quint_ease_in = quint_ease_in,
    quint_ease_out = quint_ease_out,
    quint_ease_inout = quint_ease_inout,
    expo_ease_in = expo_ease_in,
    expo_ease_out = expo_ease_out,
    expo_ease_inout = expo_ease_inout,
    circ_ease_in = circ_ease_in,
    circ_ease_out = circ_ease_out,
    circ_ease_inout = circ_ease_inout,
    back_ease_in = back_ease_in,
    back_ease_out = back_ease_out,
    back_ease_inout = back_ease_inout,
    elastic_ease_in = elastic_ease_in,
    elastic_ease_out = elastic_ease_out,
    elastic_ease_inout = elastic_ease_inout,
    bounce_ease_in = bounce_ease_in,
    bounce_ease_out = bounce_ease_out,
    bounce_ease_inout = bounce_ease_inout
}

return table.freeze(easings)
