local action = require "./action"()
local cleanup = require "./cleanup"
local effect = require "./effect"

type Tags = string | { string }

local function build_set(value: Tags): { [string]: true }
    local set: { [string]: true } = {}
    if type(value) == "string" then
        set[value] = true
    else
        for _, name in value do
            if type(name) ~= "string" then
                error("tag() expects a string or an array of strings", 0)
            end
            set[name] = true
        end
    end
    return set
end

local function tag(value: Tags | () -> Tags)
    return action(function(instance)
        if type(value) == "function" then
            local current: { [string]: true } = {}

            effect(function()
                local new_set = build_set((value :: () -> Tags)())

                for name in current do
                    if not new_set[name] then
                        instance:RemoveTag(name)
                    end
                end

                for name in new_set do
                    if not current[name] then
                        instance:AddTag(name)
                    end
                end

                current = new_set
            end)

            cleanup(function()
                for name in current do
                    instance:RemoveTag(name)
                end
            end)
        else
            local set = build_set(value)

            for name in set do
                instance:AddTag(name)
            end

            cleanup(function()
                for name in set do
                    instance:RemoveTag(name)
                end
            end)
        end
    end)
end

type Action = typeof(action(nil :: any))

return tag :: ((tag: string) -> Action)
    & ((tags: { string }) -> Action)
    & ((source: () -> string) -> Action)
    & ((source: () -> { string }) -> Action)
