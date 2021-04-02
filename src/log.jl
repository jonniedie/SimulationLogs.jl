Base.@kwdef mutable struct SimulationLog
    values::Dict{Symbol, Vector{Any}} = Dict{Symbol, Vector{Any}}()
    is_active::Bool = false
end

function Base.show(io::IO, log::SimulationLog)
    println(io, "SimulationLog with variables:")
    for (name, val) in values(log)
        println("  $name")
    end
end

# Field access
Base.values(log::SimulationLog) = getfield(log, :values)
is_active(log::SimulationLog) = getfield(log, :is_active)

# Setting fields
activate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, true)
deactivate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, false)
reset!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :values, Dict{Symbol, Vector{Any}}())

# Value access
Base.propertynames(log::SimulationLog) = Tuple(keys(values(log)))
Base.getproperty(log::SimulationLog, s::Symbol) = values(log)[s]
function Base.setproperty!(log::SimulationLog, s::Symbol, val)
    val_dict = values(log)
    val_dict[s] = val
end


"""
    @log var_name = val

Log the value `val` to `GLOBAL_LOG` variable `var_name` while setting `var_name` in local scope
"""
macro log(expr)
    if !is_active(GLOBAL_LOG[])
        return esc(expr)
    end

    return if expr.head == :(=)
        var_name = (expr.args[1],)
        quote
            local val = $(esc(expr.args[2]))
            if !haskey(values(GLOBAL_LOG[]), $(var_name)[1])
                setproperty!(GLOBAL_LOG[], $(var_name)[1], [])
            end
            push!(getindex(values(GLOBAL_LOG[]), $(var_name)[1]), val)
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
    if !is_active(GLOBAL_LOG[])
        return esc(expr)
    end
    var_name = (var_name,)
    quote
        local val = $(esc(expr))
        if !haskey(values(GLOBAL_LOG[]), $(var_name)[1])
            setproperty!(GLOBAL_LOG[], $(var_name)[1], [])
        end
        push!(getindex(values(GLOBAL_LOG[]), $(var_name)[1]), val)
        val
    end
end
