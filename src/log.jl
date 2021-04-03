"""
    @log var_name = val

Log the value `val` to `GLOBAL_LOG` variable `var_name` while setting `var_name` in local scope
"""
macro log(expr)
    return if expr.head == :(=)
        quote
            if is_active(GLOBAL_LOG[])
                local val = $(esc(expr.args[2]))
                local var_name = $((expr.args[1],))[1]
                if !haskey(values(GLOBAL_LOG[]), var_name)
                    setproperty!(GLOBAL_LOG[], var_name, typeof(val)[])
                end
                push!(getindex(values(GLOBAL_LOG[]), var_name), val)
            end
            $(esc(expr))
        end
    else
        :(error("Must be logging to some variable, use either `@log var_name val` or `@log var_name = val` forms"))
    end
end

"""
    @log var_name val

Log the value `val` to `GLOBAL_LOG` variable `var_name` without setting `var_name` in local scope
"""
macro log(var_name, expr)
    quote
        local val = $(esc(expr))
        if is_active(GLOBAL_LOG[])
            local var_name = $((var_name,))[1]
            if !haskey(values(GLOBAL_LOG[]), var_name)
                setproperty!(GLOBAL_LOG[], var_name, typeof(val)[])
            end
            push!(getindex(values(GLOBAL_LOG[]), var_name), val)
        end
        val
    end
end
