@userplot Scope

"""
    scope(sol, varnames)
    scope!(sol, varnames)

Plot the variables in `varnames` from an `ODESolution` `sol`.
If `varnames` is a vector, the variables will be plotted against
time on the same axis. If `varnames` is a tuple, the variables
will be plotted against each other.
"""
@recipe function f(s::Scope)
    sol, vars = s.args
    t = range(sol.prob.tspan..., length=200)
    signals = get_log(sol, t)
    seriestype := :path
    xguide --> "t"
    if vars isa Symbol
        vars = [vars]
    end

    if vars isa AbstractArray
        for var in vars
            @series begin
                label --> "$(string(var))(t)"
                t, getproperty(signals, var)
            end
        end

    else vars isa Tuple
        @series begin
            label --> string(vars)
            map(var->getproperty(signals, var), vars)
        end
    end
end