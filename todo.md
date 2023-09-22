# todo

- property binding optimization
  - would no longer allow `cleanup()` usage in binding scopes
- solution to nested reactivity, see: SolidJS stores
- optimize wide graph updating
- implement from solid:
  - Portal
  - batch
- optimize `indexes()` double-diffing
- improve crash course, some sections feel like information dumps
- reactive scopes
  - define behavior of creating a reactive scope within a non-root reactive scope
    - i.e. an effect within an effect
    - error on attempt for now
  - define behavior of destruction of a node with a child, where the node and
    its child are in separate, non-nested root reactive scopes.
    - should destruction of the parent also destroy the child?
    - or should destruction of the parent silently disconnect the child, without
      invoking the child's cleanups?

    ```mermaid
    graph LR

    subgraph root1
        parent
    end

    subgraph root2
        child
    end

    parent --> child
    ```
