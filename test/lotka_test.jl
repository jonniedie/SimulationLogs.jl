using DiffEqCallbacks
using OrdinaryDiffEq
using SimulationLogs
using Test

function lotka!(du, u, p, t)
    @log t
    @log x, y = u
    @log α, β, δ, γ = p

    @log total_population = x + y

    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y
end
function lotka(u, p, t)
    du = similar(u)
    lotka!(du, u, p , t)
    return du
end

lotka_sols = let
    p = [2/3, 4/3, 1, 1]
    u0 = [0.9, 0.9]
    tspan = (0.0, 10.0)

    callback = PresetTimeCallback(1:10, integrator->(integrator.p[end] += 0.01))
    prob_oop = ODEProblem(lotka, u0, tspan, p)
    prob_iip = ODEProblem(lotka!, u0, tspan, p)

    sol_oop = logged_solve(prob_oop, Tsit5())
    sol_iip = logged_solve(prob_iip, Tsit5())
    sol_oop_cb = logged_solve(prob_oop, Tsit5(); callback=callback)
    sol_iip_cb = logged_solve(prob_iip, Tsit5(); callback=callback)
    sol_oop_cbset = logged_solve(prob_oop, Tsit5(); callback=CallbackSet(callback))
    sol_iip_cbset = logged_solve(prob_iip, Tsit5(); callback=CallbackSet(callback))

    sols_iip = [sol_iip, sol_iip_cb, sol_iip_cb]
    sols_oop = [sol_oop, sol_oop_cb, sol_oop_cb]

    (iip=sols_iip, oop=sols_oop)
end


@testset "Lotka example" begin
    test_all(f, i=:) = all(f, lotka_sols.iip[i]) && all(f, lotka_sols.oop[i])
    test_cb(f) = test_all(f, 2:3)

    @testset "Logged values" begin
        @test test_all(sol->sol.log.γ[1]==1)
        @test test_all(sol->sol.log.x==sol[1,:])
        @test test_all(sol->sol.log.y==sol[2,:])
        @test test_all(sol->sol.log.t==sol.t)

        @test test_all(sol->all(sol.log.α .== sol.prob.p[1]))
        @test test_cb(sol->sol.log.γ[end] == 1.1)
    end

    this_sol = lotka_sols.iip[1]

    @testset "Indexing" begin
        @test this_sol[1] == this_sol.u[1]
        @test this_sol[:] == this_sol.u
        @test this_sol[:, :] == reduce(hcat, this_sol.u)
    end

    @testset "Interpolation" begin
        @test this_sol(10) ≈ this_sol.u[end]
    end

    @testset "Properties" begin
        @test this_sol.log isa SimulationLog
        @test this_sol.alg == this_sol.sol.alg
        @test Set(propertynames(this_sol)) == Set((:log, propertynames(this_sol.sol)...))
    end

    @testset "Printing" begin
        sol_string = @capture_out(print(this_sol))
        sol_sol_string = @capture_out(print(this_sol.sol))
        @test contains(sol_string, sol_sol_string)
    end
end

