"""
    SimulationLog(; value_dict::Dict{Symbol,Vector}=Dict{Symbol,Vector}(), is_active::Bool=false)

A log of saved variables from a simulation. Variables can be accessed with dot notation or the `getproperty`
function.
"""
Base.@kwdef mutable struct SimulationLog
    value_dict::Dict{Symbol, Array} = Dict{Symbol, Array}()
    is_active::Bool = false
end

function Base.show(io::IO, log::SimulationLog)
    println(io, "SimulationLog with signals:")
    for (name, val) in value_dict(log)
        println(io, "  $name :: $(typeof(val))")
    end
end


# Field access
"""
    value_dict(log::SimulationLog)

Get the value dictionary of a `SimulationLog`.
"""
value_dict(log::SimulationLog) = getfield(log, :value_dict)

"""
    is_active(log::SimulationLog)

See if simulation is currently active (able to be logged to).
"""
is_active(log::SimulationLog) = getfield(log, :is_active)


# Setting fields
"""
    activate!(log::SimulationLog=GLOBAL_LOG)

Activate a `SimulationLog`. If no log is given, activate the `GLOBAL_LOG`.
"""
activate!(log::SimulationLog=GLOBAL_LOG) = setfield!(log, :is_active, true)


"""
    deactivate!(log::SimulationLog=GLOBAL_LOG)

Deactivate a `SimulationLog`. If no log is given, deactivate the `GLOBAL_LOG`.
"""
deactivate!(log::SimulationLog=GLOBAL_LOG) = setfield!(log, :is_active, false)

"""
    reset!(log::SimulationLog=GLOBAL_LOG)

Reset the value dictionary of a `SimulationLog`. If no log is given, the `GLOBAL_LOG` will
be reset
"""
reset!(log::SimulationLog=GLOBAL_LOG) = setfield!(log, :value_dict, Dict{Symbol, Array}())

# Value access
Base.keys(log::SimulationLog) = keys(value_dict(log))
Base.propertynames(log::SimulationLog) = Tuple(keys(value_dict(log)))

Base.getproperty(log::SimulationLog, s::Symbol) = value_dict(log)[s]
function Base.setproperty!(log::SimulationLog, s::Symbol, val)
    val_dict = value_dict(log)
    val_dict[s] = val
end

Base.getindex(log::SimulationLog, s::Symbol) = getproperty(log, s)
Base.setindex!(log::SimulationLog, val, s::Symbol) = setproperty!(log, s, val)


"""
    struct Logged{T,N,A,S<:AbstractTimeseriesSolution{T,N,A}} <: AbstractTimeseriesSolution{T,N,A}
    
    Logged(sol::AbstractTimeseriesSolution, log::SimulationLog)

Logged differential equation solution. All properties of the underlying solution
can be accessed with the `getproperty` or 'dot' accessing. The inner `SimulationLog` can
be accessed with `.log`. A `Logged` solution can be used the same way as its underlying
solution (i.e. indexed with `sol[i]` and interpolated with `sol(t)`)
"""
struct Logged{T,N,A,S<:AbstractTimeseriesSolution{T,N,A}} <: AbstractTimeseriesSolution{T,N,A}
    sol::S
    log::SimulationLog
end

function Base.show(io::IO, mime::MIME"text/plain", sol::Logged)
    show(io, mime, sol.sol)
    println(io, "\nWith logged values:")
    for (name, val) in value_dict(sol.log)
        println(io, " $name: $(join(string.(size(val)), "×"))-element $(typeof(val))")
    end
end

(sol::Logged)(args...; kwargs...) = sol.sol(args...; kwargs...)

Base.getindex(sol::Logged, i...) = getindex(sol.sol, i...)

@inline Base.getproperty(sol::Logged, s::Symbol) = getproperty(sol, Val(s))
@inline Base.getproperty(sol::Logged, ::Val{:log}) = getfield(sol, :log)
@inline Base.getproperty(sol::Logged, ::Val{:sol}) = getfield(sol, :sol)
@inline Base.getproperty(sol::Logged, ::Val{s}) where {s} = getproperty(sol.sol, s)

Base.propertynames(sol::Logged) = (:log, propertynames(sol.sol)...)
