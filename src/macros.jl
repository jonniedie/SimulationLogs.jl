"""
    @log var_name = val
    @log var_name expr

Log `var_name` to the `GLOBAL_LOG`. If `@log` is placed on an assignment for `var_name`, the variable
will also be created in the local scope. If `@log` is placed with a variable name before an expression,
the expression will run in the local scope without creating the variable in that scope.

## Example
```julia
function lorenz!(du, u, p, t)
    @log a = u[2]-u[1]
    @log b u[3]+a
    du[1] = p[1]*a
    du[2] = u[1]*(p[2]-u[3]) - u[2]
    du[3] = u[1]*u[2] - p[3]*u[3]
end
```
In this example, `a` is evaluated into the scope of the `lorenz!` function and is able to be used within
that scope. `b`, however is not evaluated into the `lorenz!` scope, so no `b` variable is created in
that scope. Both `a` and `b` will be logged.

"""
macro log(expr)
    return if expr isa Symbol
        quote
            if is_active(GLOBAL_LOG)
                local val = $(esc(expr))
                local var_name = $((expr,))[1]
                if !haskey(value_dict(GLOBAL_LOG), var_name)
                    setproperty!(GLOBAL_LOG, var_name, typeof(val)[])
                end
                push!(getindex(value_dict(GLOBAL_LOG), var_name), val)
            end
            nothing
        end
    elseif expr.head == :(=)
        if expr.args[1] isa Expr && expr.args[1].head == :tuple
            quote
                if is_active(GLOBAL_LOG)
                    local vals = $(esc(expr.args[2]))
                    local var_names = $(esc(expr.args[1].args))
                    for (var_name, val) in zip(var_names, vals)
                        if !haskey(value_dict(GLOBAL_LOG), var_name)
                            setproperty!(GLOBAL_LOG, var_name, typeof(val)[])
                        end
                        push!(getindex(value_dict(GLOBAL_LOG), var_name), val)
                    end
                end
                $(esc(expr))
            end
        else
            quote
                if is_active(GLOBAL_LOG)
                    local val = $(esc(expr.args[2]))
                    local var_name = $((expr.args[1],))[1]
                    if !haskey(value_dict(GLOBAL_LOG), var_name)
                        setproperty!(GLOBAL_LOG, var_name, typeof(val)[])
                    end
                    push!(getindex(value_dict(GLOBAL_LOG), var_name), val)
                end
                $(esc(expr))
            end
        end
    else
        :(error("Must be logging to some variable, use either `@log var_name val` or `@log var_name = val` forms"))
    end
end

macro log(var_name, expr)
    quote
        local val = $(esc(expr))
        if is_active(GLOBAL_LOG)
            local var_name = $((var_name,))[1]
            if !haskey(value_dict(GLOBAL_LOG), var_name)
                setproperty!(GLOBAL_LOG, var_name, typeof(val)[])
            end
            push!(getindex(value_dict(GLOBAL_LOG), var_name), val)
        end
        val
    end
end
