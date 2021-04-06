
"""
    get_log(sol)
    get_log(sol, t)

Get the variables logged by `@log` from an `ODESolution`.
"""
get_log(sol) = _get_log(sol.prob, sol.u, sol.t)
get_log(sol, t) = _get_log(sol.prob, sol(t).u, t)

function _get_log(prob, u, t)
    u = isinplace(prob) ? (zero.(u), u) : (u,)

    reset!()
    activate!()

    for i in eachindex(t)
        prob.f(getindex.(u, i)..., prob.p, t[i])
    end

    n = length(t)
    for (key, val) in values(GLOBAL_LOG)
        if length(val) != n
            if length(val) % n == 0
                setproperty!(GLOBAL_LOG, key, collect(reshape(val, :, n)'))
            else
                @warn """
                Signal $key was logged $(length(val)) times during $n timesteps. SimulationLogs
                is not currently set up to handle an ununeven number of `@log` calls per step.
                """
                delete!(values(GLOBAL_LOG), key)
            end
        end
    end

    deactivate!()
    
    out = deepcopy(GLOBAL_LOG)
    
    reset!()

    return out
end