local source = require(script.Parent.source)

local function read<T>(value: source.Source<T> | T): T
	return if typeof(value) == "function" then value() else value
end

return read
