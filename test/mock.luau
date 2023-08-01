local Instance = {} do
    local Signal = require "test/goodsignal"

    type userdata = { __USERDATA__: true }

    type Proxy = {
        _Userdata: userdata,
        _Data: Data,
        __index: any,
        __newindex: any
    }

    type Data = {
        Name: string,
        Parent: Data?,
        Children: { Data },
        Changed: { [string]: RBXScriptSignal & { Fire: any } },
        Table: { [string]: unknown },
        Destroying: RBXScriptSignal,
        ClassName: string,
        Type: "Instance"
    }

    local function deepclone<T>(template: T & {}): T
        local t = table.clone(template :: {}) :: {}

        for i, v in next, t do
            if type(v) == "table" then
                t[i] = deepclone(v)
            end
        end

        return t :: T & {}
    end

    --[[
        attempt to mimic roblox engine's method of userdata proxy to actual instance data
        proxy can gc independantly of actual instance data
        proxy prevents gc of actual instance data
        luau code never has direct access to actual instance data, only to proxy
    ]]
    local proxies = {} :: { [Data]: userdata? }
    setmetatable(proxies :: any, { __mode = "v" })

    local function getdata(userdata: userdata): Data
        local function getproxy(userdata: userdata): Proxy
            return getmetatable(userdata :: any)
        end

        return getproxy(userdata)._Data
    end

    local function isInstance(value: unknown): boolean
        local mt = getmetatable(value :: any)
        return mt and mt._Data and mt._Data.Type == "Instance"
    end

    local methods = {}

    local function __index(userdata: userdata, property: string): ()
        local data = getdata(userdata)
        return if methods[property] then methods[property]
            elseif property == "Name" then data.Name
            elseif property == "Parent" then data.Parent
            elseif property == "Destroying" then data.Destroying
            else data.Table[property] 
    end

    local function __newindex(userdata: userdata, property: string, value: unknown)
        local data = getdata(userdata)
        if property == "Name" then
            data.Name = value :: string
        elseif property == "Parent" then
            assert(value == nil or isInstance(value), "attempt to set non-instance as parent")
            local parent = data.Parent
            if parent then
                data.Parent = nil
                table.remove(parent.Children, table.find(parent.Children, data))
            end
            if value then
                data.Parent = getdata(value :: userdata)
                table.insert(getdata(value :: userdata).Children, data)
            end
        else
            data.Table[property] = value
        end

        if data.Changed[property] then
            data.Changed[property]:Fire()
        end
    end

    local function getuserdata(data: Data): userdata
        return proxies[data] or (function()
            local userdata = newproxy(true)
            local proxy = getmetatable(userdata)
            proxy._Userdata = userdata
            proxy._Data = data
            proxy.__index = __index
            proxy.__newindex = __newindex
            proxies[data] = userdata   
            return userdata
        end)()
    end

    function Instance.new(class: string): Instance
        local data = {
            Name = "UNNAMED",
            Parent = nil,
            Children = {},
            Changed = {},
            Table = {},
            ClassName = class,
            Destroying = Signal.new() :: any,
            Type = "Instance" :: "Instance"
        }

        return getuserdata(data) :: any
    end

    function Instance.isInstance(value: unknown): boolean
        return isInstance(value)
    end

    function methods.Clone(userdata: userdata): userdata
        local data = getdata(userdata)
        local clone_userdata = (Instance.new("") :: any) :: userdata
        local clone_data = getdata(clone_userdata)

        for i, v in next, deepclone(data) do
            clone_data[i] = v
        end

        return clone_userdata
    end

    function methods.FindFirstChild(userdata: userdata, target: string): userdata?
        local data = getdata(userdata)
        for _, child in data.Children do
            if child.Name == target then
                return getuserdata(child)
            end
        end
        return nil
    end

    function methods.GetChildren(userdata: userdata): { userdata }
        local children = getdata(userdata).Children
        local userdatas = table.create(#children)

        for i, child in next, children do
            userdatas[i] = getuserdata(child)
        end

        return userdatas
    end

    function methods.GetPropertyChangedSignal(userdata: userdata, property: string): RBXScriptSignal
        local data = getdata(userdata)
        if not data.Changed[property] then
            data.Changed[property] = Signal.new() :: any
        end
        return data.Changed[property]
    end

    function methods.Destroy(userdata: userdata)
        local data = getdata(userdata);
        (data.Destroying :: any):Fire()
        data.Parent = nil
        if data.Changed["Parent"] then
            data.Changed["Parent"]:Fire()
        end
    end
end

local Color3 = {} do
    function Color3.new(r, g, b): Color3
        return setmetatable({ r = r, g = g, b = b}, Color3) :: any
    end

    function Color3.__eq(a, b)
        return a.r == b.r and a.g == b.g and a.b == b.b
    end
end

local Vector3 = {} do
    function Vector3.new(x, y, z): Vector3
        return setmetatable({ x = x, y = y, z = z}, Vector3) :: any
    end

    function Vector3.__eq(a, b)
        return a.x == b.x and a.y == b.y and a.z == b.z
    end
end

local Vector2 = {} do
    function Vector2.new(x, y): Vector2
        return setmetatable({ x = x, y = y }, Vector2) :: any
    end

    function Vector2.__eq(a, b)
        return a.x == b.x and a.y == b.y
    end
end

local UDim2 = {} do
    function UDim2.fromScale(x, y): UDim2
        return setmetatable({ x = { scale = x, offset = 0 }, y = { scale = y, offset = 0 } }, UDim2) :: any
    end

    function UDim2.__eq(a, b)
        return a.x.scale == b.x.scale and
            b.x.offset == b.x.offset and
            a.y.scale == b.y.scale and
            a.y.offset == b.y.offset
    end
end

local Enum = {} :: any do
    setmetatable(Enum, { __index = function(self, index)
        local v = setmetatable({}, { __index = function(self, index) 
            self[index] = true
            return true
        end})
        self[index] = v
        return v
    end})
end

local function typeof(v)
    return Instance.isInstance(v) and "Instance" or type(v)
end

return {
    Instance = Instance,
    Color3 = Color3,
    Vector3 = Vector3,
    Vector2 = Vector2,
    UDim2 = UDim2,
    Enum = Enum,
    typeof = typeof
}
