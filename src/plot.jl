@userplot Scope

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