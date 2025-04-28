@userplot Scope

"""
    scope(sol, varnames)
    scope!(sol, varnames)

Plot the variables in `varnames` from an `ODESolution` `sol`.
If `varnames` is a vector, the variables will be plotted against
time on the same axis. If `varnames` is a tuple, the variables
will be plotted against each other.
"""
scope, scope!

@recipe function f(s::Scope)
    sol, vars = s.args
    t = range(extrema(sol.t)..., length=2000)
    signals = get_log(sol, t)
    seriestype := :path
    xguide --> "t"
    if vars isa Symbol
        vars = [vars]
    end

    if vars isa AbstractArray
        for var in vars
            @series begin
                x = getproperty(signals, var)
                if x isa AbstractMatrix
                    sizes = string.(permutedims(1:size(x, 2)))
                    label --> string(var) * "[:," .* sizes .* "]"
                elseif x isa AbstractVector{<:AbstractVector}
                    x = stack(x)'
                    sizes = string.(permutedims(1:size(x, 2)))
                    label --> string(var) * "[" .* sizes .* "]"
                else
                    label --> "$(string(var))"
                end
                t, x
            end
        end

    else vars isa Tuple
        @series begin
            label --> "("*join(string.(vars), ", ")*")"
            map(var->getproperty(signals, var), vars)
        end
    end
end