
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

    deactivate!()
    
    out = deepcopy(GLOBAL_LOG[])
    
    reset!()

    return out
end