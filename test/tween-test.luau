local vide = require "../../vide"

local function system(): (number) -> number
    local MAX = 40
    local MIN = 10

    local _, input, output = vide.root(function()
        local input = vide.source(MAX)
        local output = vide.tween(input, { time = 2, style = "quad_ease_inout" })
        return input, output
    end)

    local T = 3
    local t = 0
    return function(dt)
        t += dt
        if t >= T then
            t -= T
            input(input() == MAX and MIN or MAX)
        end

        vide.step(dt)

        return output()
    end
end

--------------------------------------------------------------------------------

local function redraw_block(h: number)
    local OFFSET = 70

    local BLOCK = "█"

    local function remainder_to_block(x)
        return
            if x > 7/8 then "█"
            elseif x > 6/8 then "▇"
            elseif x > 5/8 then "▆"
            elseif x > 4/8 then "▅"
            elseif x > 3/8 then "▄"
            elseif x > 2/8 then "▃"
            elseif x > 1/8 then "▂"
            else "▁"
    end

    -- math.clamp added just in case an Elastic/Back easing style overshoots below 0
    local h_f = math.max(0, math.floor(h))
    local reset = "\27[H\27[2J" -- ANSI clear terminal
    local offset = string.rep("\n", math.max(0, OFFSET - h_f))
    local bar = remainder_to_block(h - h_f) .. "\n" .. string.rep(BLOCK .. "\n", h_f)
    print(reset .. offset .. bar .. "\n" .. h)
end

local program_time = os.clock()

local function step(): number
    local FPS = 30
    local DT = 1/FPS

    repeat until os.clock() - program_time >= DT
    program_time += DT
    return DT
end

local function loop()
    local callback = system()

    while true do
        local dt = step()
        local x = callback(dt)
        redraw_block(x)
    end
end

loop()
