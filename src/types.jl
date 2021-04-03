"""
    SimulationLog(; values::Dict{Symbol,Vector}=Dict{Symbol,Vector}(), is_active::Bool=false)

A log of saved variables from a simulation. Variables can be accessed with dot notation or the `getproperty`
function.
"""
Base.@kwdef mutable struct SimulationLog
    values::Dict{Symbol, Vector} = Dict{Symbol, Vector}()
    is_active::Bool = false
end

function Base.show(io::IO, log::SimulationLog)
    println(io, "SimulationLog with signals:")
    for (name, val) in values(log)
        println(io, "  $name :: $(eltype(val))")
    end
end


# Field access
"""
    values(log::SimulationLog)

Get the value dictionary of a `SimulationLog`.
"""
Base.values(log::SimulationLog) = getfield(log, :values)

"""
    is_active(log::SimulationLog)

See if simulation is currently active (able to be logged to).
"""
is_active(log::SimulationLog) = getfield(log, :is_active)


# Setting fields
"""
    activate!(log::SimulationLog=GLOBAL_LOG[])

Activate a `SimulationLog`. If no log is given, activate the `GLOBAL_LOG`.
"""
activate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, true)


"""
    deactivate!(log::SimulationLog=GLOBAL_LOG[])

Deactivate a `SimulationLog`. If no log is given, deactivate the `GLOBAL_LOG`.
"""
deactivate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, false)

"""
    reset!(log::SimulationLog=GLOBAL_LOG[])

Reset the value dictionary of a `SimulationLog`. If no log is given, the `GLOBAL_LOG` will
be reset
"""
reset!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :values, Dict{Symbol, Vector}())

# Value access
Base.propertynames(log::SimulationLog) = Tuple(keys(values(log)))
Base.getproperty(log::SimulationLog, s::Symbol) = values(log)[s]
function Base.setproperty!(log::SimulationLog, s::Symbol, val)
    val_dict = values(log)
    val_dict[s] = val
end
