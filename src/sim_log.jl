function extract(sol)
    t = sol.t
    u = sol.u
    prob = sol.prob
    p = prob.p
    f = prob.f

    u = isinplace(prob) ? (zero.(u), u) : (u,)

    activate!()

    for i in eachindex(sol)
        f(getindex.(u, i)..., p, t[i])
    end

    out = deepcopy(GLOBAL_LOG[])

    reset!()
    deactivate!()

    return out
end