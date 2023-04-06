--------------------------------------------------------------------------------------------------------------
-- vide/each.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type Node<T> = graph.Node<T>
local create = graph.create
local get = graph.get
local wrapped = graph.wrapped
local link = graph.link

type Map<K, V> = { [K]: V }

local function each<K, VI, VO>(input: State<Map<K, VI>>, transform: (K, VI) -> VO, cleanup: (VO) -> ()?)
    
end

return (each :: any) ::  ( <V>(input: number, transform: (number) -> V) -> Map<number, V> ) &
                        ( <K, VI, VO>(input: Map<K, VI>, transform: (K, VI) -> VO) -> Map<K, VO> ) &
                        ( <K, VI, VO>(input: State<Map<K, VI>>, transform: (K, VI) -> VO, cleanup: (VO) -> ()?)
                            -> State<Map<K, VO>> )
