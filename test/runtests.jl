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
    sol = solve(prob)

    out = get_log(sol)

    @testset "Lorenz example" begin
        a = [u[2]-u[1] for u in sol.u]
        b = [u[3]+(u[2]-u[1]) for u in sol.u]
        c = [p[1]*(u[2]-u[1]) for u in sol.u]
        d = [n*u[1] for u in sol.u, n in 1:5]

        @test out.a == a
        @test out.b == b
        @test out.c == c
        @test out.d == d

        @test out.a == out[:a]

        @test typeof(out.a) === typeof(a)
        @test typeof(out.b) === typeof(b)
        @test typeof(out.c) === typeof(c)
        @test typeof(out.d) === typeof(d)

        @test Set(propertynames(out)) == Set((:a, :b, :c, :d))

        @test is_active(out) === false
    end
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
    
    @test isempty(values(glog))
    glog[:a] = zeros(5)
    @test glog.a == zeros(5)
    @test glog[:a] == zeros(5)
    reset!()
    @test_throws KeyError glog.a
    @test_throws KeyError glog[:a]
    @test isempty(values(glog))
end