using OrdinaryDiffEq
using SimulationLogs
using Test

function lotka!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p

    @log total_population = x + y
    @log γ γ

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
    compare_iip_oop(s) = all(map((iip,oop)->getproperty(iip.log, s)==getproperty(oop.log, s), lotka_sols...))

    @test test_all(x->x.log.γ[1]==1)
    @test test_cb(x->x.log.γ[end]==1.1)

    @test compare_iip_oop(:γ)
    @test compare_iip_oop(:total_population)
end