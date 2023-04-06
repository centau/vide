--------------------------------------------------------------------------------------------------------------
-- vide/Types.lua
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)

type State<T> = graph.State<T>
type MaybeState<T> = graph.MaybeState<T>

export type Symbol<T> = {
    priority: number,
    run: (Instance, T) -> ()
}

export type Children = Instance | State<Children> | { Children }

return {}
