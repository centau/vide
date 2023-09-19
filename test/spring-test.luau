local vide = require "src/init"
local testkit = require("test/testkit")

local program_time = os.clock()

local function step(): number
    local FPS = 60
    local DT = 1/FPS

    repeat until os.clock() - program_time >= DT*10
    program_time += DT*10
    return DT
end

local function main()
    local TERMINAL_HEIGHT = 73 --* REDUCE IF BAR DOES NOT FIT IN TERMINAL
    local MIN_ALPHA = 0.3
    local MAX_ALPHA = 0.7

    local MIN = TERMINAL_HEIGHT * MIN_ALPHA
    local MAX = TERMINAL_HEIGHT * MAX_ALPHA
    local OFFSET = TERMINAL_HEIGHT - MAX

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

    local source = vide.source
    local spring = vide.spring
    local effect = vide.effect

    local value = source(MAX)
    local sprung, data = (spring :: any)(value, 1, 19.6)

    effect(function()
        local v = sprung()
        local fv = math.floor(v)
        local reset = "\27[H\27[2J" -- ANSI clear terminal
        local offset = string.rep("\n", MAX - fv + OFFSET)
        local bar = testkit.color.gray(remainder_to_block(v - fv) .. "\n" .. string.rep(BLOCK .. "\n", fv))
        local num = "\n" .. v
        local test = "\n" .. (data.a or 0)
        local test2 = "\n" .. (data.b or 0)
        print(reset .. offset .. bar .. num .. test .. test2)
    end)
    
    local T = 1.5
    local elapsed = T/2
    repeat local dt = step()
        vide.step(dt)

        elapsed += dt
        while elapsed >= T do
            elapsed -= T
            value(value() == MAX and MIN or MAX)
        end

    until false
end

vide.root(main)



