export type CanBeSource<T> = T | (() -> T)

local function read<T>(value: CanBeSource<T>): T
    return if type(value) == "function" then value() else value
end

return read
