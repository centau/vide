local function dir(directory: string)
    return setmetatable({} :: { [string]: any },
    { __index = function(_, path) return directory .. path end })
end

local script = dir "src/"
script.Parent = dir "src/"

return script
