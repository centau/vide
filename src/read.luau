type function CastIntoValue(value: type)

    local function get_return_for_fn(t: type)
        local values = t:returns()
        local head = values.head
        local tail = values.tail

        if head then
            local first = head[1]
            return first
        elseif tail then
            return tail
        else
            return types.singleton(nil)
        end
    end

    if value.tag == "union" then
        local components = value:components()
        local possible_outcomes = {}

        for _, v in components do
            if v.tag == "function" then
                table.insert(possible_outcomes, get_return_for_fn(v))
            else
                table.insert(possible_outcomes, v)
            end
        end

        return types.unionof(unpack(possible_outcomes))
    elseif value.tag == "function" then
        return get_return_for_fn(value)
    else
        return value
    end
end

local function read<T>(value: T): CastIntoValue<T>
    return if type(value) == "function" then (value :: () -> T)() else value
end

return read