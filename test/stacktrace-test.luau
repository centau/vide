local vide = require "../"

do
    print "============================================================="

    local a = vide.source(1)

    local cause_error = false
    
    local function try_error()
        if cause_error then error("uh oh") end
    end
    
    vide.root(function()
        vide.effect(function()
            a()
            try_error()
        end)
    end)
    
    cause_error = true

    local ok, result = pcall(function() a(2) end)
    print(result)

    print "============================================================="
end

do
    print "============================================================="

    local a = vide.source(1)
    local b = vide.source(1)
    local c = vide.source(1)

    local cause_error = false

    local function try_error()
        if cause_error then error("uh oh") end
    end

    vide.root(function()
        vide.effect(function()
            a()
            b(vide.untrack(b) + 1)
        end)

        vide.effect(function()
            b()
            c(vide.untrack(c) + 1)
        end)

        
        vide.effect(function()
            c()
            try_error()
        end)
    end)

    cause_error = true

    local ok, result = pcall(function() a(2) end)
    print(result)

    print "============================================================="
end

do
    print "============================================================="

    local a = vide.source(1)
    local b = vide.source(1)
    local c = vide.source(1)

    local cause_error = false

    local function try_error()
        if cause_error then error("uh oh") end
    end

    vide.root(function()
        vide.effect(function()
            a()
            vide.untrack(function() -- todo: this trace appearing twice
                b(b() + 1)
                return nil
            end)
        end)

        vide.effect(function()
            b()
            vide.batch(function()
                c(vide.untrack(c) + 1)
            end)
        end)

        
        vide.effect(function()
            c()
            try_error()
        end)
    end)

    cause_error = true

    local ok, result = pcall(function() a(2) end)
    print(result)

    print "============================================================="
end
