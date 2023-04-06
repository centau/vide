--------------------------------------------------------------------------------------------------------------
-- vide/map.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>
local create = graph.create
local get = graph.get
local wrapped = graph.wrapped
local link = graph.link

type Map<K, V> = { [K]: V }

local function map<K, VI, VO>(input: unknown, transform: (K, VI) -> VO, cleanup: (VO) -> ()?): (MaybeState<Map<K, VO>>)
    if type(input) == "number" then
        local output: Map<K, VO> = table.create(input) :: {}

        for i = 1, input do
            local v = transform(i :: any, nil :: any)
            output[i :: any] = v
        end

        return output
    elseif wrapped(input) then
        local lastInput: Map<K, VI> = {}
        local lastOutput: Map<K, VO> = {}
        local output = create(lastOutput)

        local function derive()
            local newInput = get(input :: State<Map<K, VI>>)
            if type(newInput) ~= "table" then error("Attempt to run map on a non-table state", 0) end

            local lastInputClone = table.clone(lastInput)

            for k, vi in next, newInput do
                if vi ~= lastInputClone[k] then
                    local vo = transform(k, vi)
                    if cleanup and lastOutput[k] then cleanup(lastOutput[k]) end
                    lastInput[k] = vi
                    lastOutput[k] = vo
                end
                lastInputClone[k] = nil
            end

            for k, v in next, lastInputClone do
                lastInput[k] = nil
                if cleanup and lastOutput[k] then cleanup(lastOutput[k]) end   
                lastOutput[k] = nil
            end

            return table.clone(lastOutput)
        end

        link(input :: State<Map<K, VI>>, output, derive)
        output.updated = true

        return output
    elseif type(input) == "table" then
        local output: Map<K, VO> = table.create(#input :: any) :: {}

        for k, vi in input :: Map<K, VI> do
            local vo = transform(k, vi)
            output[k] = vo
        end

        return output
    else error(string.format("Invalid type arg #1, expected number or table or state (got %s)", tostring(input)), 2) end
end

return (map :: any) ::  ( <V>(input: number, transform: (number) -> V) -> Map<number, V> ) &
                        ( <K, VI, VO>(input: Map<K, VI>, transform: (K, VI) -> VO) -> Map<K, VO> ) &
                        ( <K, VI, VO>(input: State<Map<K, VI>>, transform: (K, VI) -> VO, cleanup: (VO) -> ()?)
                            -> State<Map<K, VO>> )
