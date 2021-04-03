using DifferentialEquations
using SimulationLogs
using Test

let
    function lorenz!(du, u, p, t)
        @log a = u[2]-u[1]
        @log b u[3] + a
        @log c du[1] = p[1]*a
        du[2] = u[1]*(p[2]-u[3]) - u[2]
        du[3] = u[1]*u[2] - p[3]*u[3]
    end

    p = [10.0, 28.0, 8/3]
    u0 = [1.0, 0.0, 0.0]
    tspan = (0.0, 100.0)

    prob = ODEProblem(lorenz!, u0, tspan, p)
    sol = solve(prob)

    out = get_log(sol)

    @testset "Lorenz example" begin
        a = [u[2]-u[1] for u in sol.u]
        b = [u[3]+(u[2]-u[1]) for u in sol.u]
        c = [p[1]*(u[2]-u[1]) for u in sol.u]

        @test out.a == a
        @test out.b == b
        @test out.c == c

        @test typeof(out.a) === typeof(a)
        @test typeof(out.b) === typeof(b)
        @test typeof(out.c) === typeof(c)

        @test propertynames(out) == (:a, :b, :c)

        @test is_active(out) === false
    end
end

@testset "Global log" begin
    glog = SimulationLogs.GLOBAL_LOG[]

    @test propertynames(glog) === ()

    @test is_active(glog) === false
    
    @test isempty(values(glog))
end