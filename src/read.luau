local function read<T>(value: ((() -> T) & ((value: T) -> T)) | T): T
	return if typeof(value) == "function" then value() else value
end

return read
