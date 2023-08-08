type Action = {
    priority: number,
    callback: (Instance) -> ()
}

local ActionMT = {}

local function is_action(v: any)
    return getmetatable(v) == ActionMT
end

local function action(callback: (Instance) -> (), priority: number?): Action
    local t = {
        priority = priority or 1,
        callback = callback
    }

    setmetatable(t :: any, ActionMT)

    return t
end

return function()
    return action, is_action
end
