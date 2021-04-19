"""
    logged_solve(prob, args...; kwargs...)

Create a `Logged` ODE solution whose logged variables can be accessed through the `.log`
property.

See also: [`get_log`](@ref), [`solve`](@ref)
"""
function logged_solve(prob, args...; callback=nothing, kwargs...)
    p = deepcopy(prob.p)
    sol = solve(deepcopy(prob), args...; callback=callback, kwargs...)
    log = _get_log(isinplace(prob), prob.f, sol.u, p, sol.t, callback)
    return Logged(sol, log)
end


"""
    get_log(sol; callback=nothing)
    get_log(sol, t; callback=nothing)

Get the variables logged by `@log` from an `ODESolution`. If a callback or callback set
was used to change parameters during the simulation, it must be passed in through the keyword
`callback` to obtain correct results. When doing this, be sure to reset any parameters that
changed over the course of the simulation to their starting values.

Alternatively, replace your `solve` call with `logged_solve` to handle this all automatically.

See also: [`logged_solve`](@ref)
"""
get_log(sol; callback=nothing) = _get_log(isinplace(sol.prob), sol.prob.f, sol.u, sol.prob.p, sol.t, callback)
get_log(sol, t; callback=nothing) = _get_log(isinplace(sol.prob), sol.prob.f, sol(t).u, sol.prob.p, t, callback)
get_log(sol::Logged) = getfield(sol, :log)
get_log(sol::Logged, t) = error("Sorry, `get_log(sol::Logged, t)` does not currently work. Use `get_log(logged_solve(prob, ...; saveat=t))` or `get_log(solve(prob, ...), t)`")

function _get_log(iip, f, u, p, t, callback)
    u = iip ? (zero.(u), u) : (u,)

    reset!()
    activate!()

    _run_funcs(f, u, deepcopy(p), t, callback)

    deactivate!()
    log = deepcopy(GLOBAL_LOG)
    reset!()

    return _postprocess(log, length(t))
end

function _run_funcs(f, u, p, t, callbacks::CallbackSet)
    @assert isempty(callbacks.continuous_callbacks) "Sorry, SimulationLogs can't handle continuous callbacks yet"
    _run_funcs(f, u, p, t, callbacks.discrete_callbacks...)
end
function _run_funcs(f, u, p, t, ::Nothing)
    for i in eachindex(t)
        f(getindex.(u, i)..., p, t[i])
    end
end
function _run_funcs(f, du_u, p, t, callbacks::DiscreteCallback...)
    u = _get_u(du_u...)
    integrator = (; u=u, p=p, t=t)
    f(getindex.(_set_u(du_u..., integrator.u), 1)..., p, t[1])
    hit_last = true
    for i in 2:length(t)
        for callback in callbacks
            hit = callback.condition(integrator.u, t[i], integrator)
            # TODO: See if this works
            if hit==callback.save_positions[1] && hit_last==callback.save_positions[1]
                callback.affect!(integrator)
            end
            hit_last = hit
        end
        f(getindex.(_set_u(du_u..., integrator.u), i)..., p, t[i])
    end
end

_get_u(du, u) = u
_get_u(u) = u

_set_u(du, u_old, u_new) = (du, u_new)
_set_u(u_old, u_new) = (u_new,)

function _postprocess(log, n)
    for (key, val) in value_dict(log)
        if length(val) != n
            if length(val) % n == 0
                setproperty!(log, key, collect(permutedims(reshape(val, :, n))))
            else
                @warn """
                Signal $key was logged $(length(val)) times during $n timesteps. SimulationLogs
                is not currently set up to handle a mixed number of `@log` calls per step.
                """
                delete!(value_dict(log), key)
            end
        end
    end
    
    return log
end