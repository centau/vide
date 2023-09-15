# Reactive Scoping

This is a brief document designed to give the user more insight into how Vide's
reactive graph works.

Each time you create and derive sources, a new node representing that source is
created and added to the reactive graph. Each node stores a value and a
side-effect function. Each node also keeps track of its parents and children,
as well as any cleanups registered.

Any time a node is updated, Vide will traverse and update that node's children,
its children's children, etc, until all nodes descending from that node has been
updated. Traversal will stop at a node if that node's cached value does not
change after an update.

For every node that is updated, a scope is opened for that node. These scopes
are referred to as "reactive scopes". Any source read from within a node's scope
will that node as a child. This is similar to cleanups, anytime a cleanup is
registered, it is added to the node of the currently active scope.

The way Vide tracks reactive scopes, is by using a stack of nodes. The current
active reactive scope is the node at the top of this stack.

When destroying a node, its descendents are traversed and also destroyed.
When being destroyed, a node's connections (parents and children) are cleared,
and any pending cleanup functions are ran.

The purpose of `root()` (which is called internally by `mount()`) is to setup
the root node which will track any node created or derived inside its scope, or
any cleanups registered. Without it, nodes could be garbage collected without a
chance to run pending cleanups which can cause memory leakage.

Control flow functions in Vide are special, as they can dynamically create and
destroy new root scopes.

It is the combination of the above which allows us to write components like so:

```lua
local function Counter()
    local count = source(0)

    local connection = stepped:Connect(function() count(count() + 1) end)

    cleanup(function() connection:Disconnect() end)
    effect(function() print(count()) end)

    return create "TextLabel" { Text = count }
end
```

Vide doesn't recognise this as a "component", that is a user abstraction. Vide
just sees this as a function that creates nodes in the reactive graph.

Whenever the reactive scope that calls this function is destroyed, like by a
control flow function, the registered cleanup will be called, and the effect
(which is just a node on the reactive graph) is destroyed. The returned instance
and the bound `count` source is just considered to be a side-effect, and with
the reactive scope from which the side-effects stem from destroyed, the instance
can be garbage collected - everything is nicely cleaned up.

> todo: add graphics
