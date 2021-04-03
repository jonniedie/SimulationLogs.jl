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
Base.values(log::SimulationLog) = getfield(log, :values)
is_active(log::SimulationLog) = getfield(log, :is_active)

# Setting fields
activate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, true)
deactivate!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :is_active, false)
reset!(log::SimulationLog=GLOBAL_LOG[]) = setfield!(log, :values, Dict{Symbol, Vector}())

# Value access
Base.propertynames(log::SimulationLog) = Tuple(keys(values(log)))
Base.getproperty(log::SimulationLog, s::Symbol) = values(log)[s]
function Base.setproperty!(log::SimulationLog, s::Symbol, val)
    val_dict = values(log)
    val_dict[s] = val
end
