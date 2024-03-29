using OrdinaryDiffEq
using DiffEqCallbacks
using RecipesBase
using SimulationLogs
using Suppressor
using Test


function lorenz!(du, u, p, t)
    @log a = u[2]-u[1]
    @log b u[3] + a

    @log c du[1] = p[1]*a
    @log p1 p[1]
    du[2] = u[1]*(p[2]-u[3]) - u[2]
    du[3] = u[1]*u[2] - p[3]*u[3]
    
    accum = 0
    for i in 1:5
        accum += u[1]
        @log d accum
        if t>50
            @log e u[2]
        end
    end

    return nothing
end

p = [10.0, 28.0, 8/3]
u0 = [1.0, 0.0, 0.0]
tspan = (0.0, 100.0)

prob = ODEProblem(lorenz!, u0, tspan, p)


@testset "Lorenz example" begin
    sol = solve(prob, Tsit5())

    out = get_log(sol)

    a = [u[2]-u[1] for u in sol.u]
    b = [u[3]+(u[2]-u[1]) for u in sol.u]
    c = [p[1]*(u[2]-u[1]) for u in sol.u]
    d = [n*u[1] for u in sol.u, n in 1:5]

    @testset "Get" begin
        @test out.a == a
        @test out.b == b
        @test out.c == c
        @test out.d == d
        @test all(out.p1 .== p[1])

        @test out.a == out[:a]
    end

    @testset "Variable types" begin
        @test typeof(out.a) === typeof(a)
        @test typeof(out.b) === typeof(b)
        @test typeof(out.c) === typeof(c)
        @test typeof(out.d) === typeof(d)
    end
    
    @testset "Plot recipes" begin
        using SimulationLogs: Scope
        using RecipesBase: apply_recipe

        AnyDict = Dict{Symbol, Any}
        t = range(tspan..., length=2000)
        out = get_log(sol, t)

        rec = apply_recipe(AnyDict(), Scope((sol, :a)))
        @test only(rec).plotattributes == AnyDict(:xguide=>"t", :label=>"a", :seriestype=>:path)
        @test only(rec).args == (t, out.a)

        rec = apply_recipe(AnyDict(), Scope((sol, [:b, :c])))
        @test rec[1].plotattributes == AnyDict(:xguide=>"t", :label=>"b", :seriestype=>:path)
        @test rec[1].args == (t, out.b)
        @test rec[2].plotattributes == AnyDict(:xguide=>"t", :label=>"c", :seriestype=>:path)
        @test rec[2].args == (t, out.c)

        rec = apply_recipe(AnyDict(), Scope((sol, (:a, :c))))
        @test only(rec).plotattributes == AnyDict(:xguide=>"t", :label=>"(a, c)", :seriestype=>:path)
        @test only(rec).args == (out.a, out.c)

        rec = apply_recipe(AnyDict(), Scope((sol, :d)))
        @test only(rec).plotattributes == AnyDict(:xguide=>"t", :label=>["d[:,$i]" for i in (1:5)'], :seriestype=>:path)
        @test only(rec).args == (t, out.d)
    end

    @testset "Printing" begin
        @test @capture_out(print(out)) ==
        """
        SimulationLog with signals:
          a :: $(typeof(out.a))
          b :: $(typeof(out.b))
          d :: $(typeof(out.d))
          c :: $(typeof(out.c))
          p1 :: $(typeof(out.p1))
        """
    end

    @testset "Miscellaneous" begin
        @test Set(propertynames(out)) == Set((:a, :b, :c, :d, :p1))

        @test is_active(out) === false

        @test_logs () get_log(sol)
    end
end

@testset "Callbacks" begin
    d_callback = PresetTimeCallback(Int(tspan[1]):Int(tspan[2]), integrator->(integrator.p[1] += 0.01))
    callback_set = CallbackSet(d_callback)
    prob.p[1] = 10.0
    sol = logged_solve(prob, Tsit5(); callback=callback_set)
    prob.p[1] = 10.0
    out = get_log(sol)

    @test out.c[1] == p[1]*(u0[2]-u0[1])
    @test !all(out.c .≈ [p[1]*(u[2]-u[1]) for u in sol.u])
    @test !all(==(p[1]), out.p1)
    @test out.p1[end] ≈ 11
end

@testset "Logged solution" begin
    include("lotka_test.jl")
end

@testset "Global log" begin
    using SimulationLogs: activate!, deactivate!, reset!

    glog = SimulationLogs.GLOBAL_LOG

    @test propertynames(glog) === ()

    @test collect(keys(glog)) == Symbol[]

    @test is_active(glog) === false
    activate!()
    @test is_active(glog) === true
    deactivate!()
    
    @test isempty(value_dict(glog))
    glog[:a] = zeros(5)
    @test glog.a == zeros(5)
    @test glog[:a] == zeros(5)
    reset!()
    @test_throws KeyError glog.a
    @test_throws KeyError glog[:a]
    @test isempty(value_dict(glog))
end