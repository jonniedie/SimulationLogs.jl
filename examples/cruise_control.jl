using ComponentArrays
using DifferentialEquations
using SimulationLogs
using Plots


## Simulation functions
# Simple car with velocity-square drag
function car!(D, x, p, t; u=0.0)
    @log drag = p.CdA*x.vel^2
    D.pos = x.vel
    D.vel = (-drag*sign(x.vel) + u)/p.m
end

# Car with cruise control
function feedback_car!(D, vars, p, t)
    @log r = p.control.ref(t)
    @log e = r - vars.car.vel
    @log u = p.control.kp*e + p.control.ki*vars.∫e
    
    car!(D.car, vars.car, p.car, t; u)
    D.∫e = e
end


## Inputs
# Parameters
p = (
    car = (
        m = 1000,
        CdA = 5,
    ),
    control = (
        ref = t -> 10*(t>1),
        kp = 800,
        ki = 40,
    )
)

# Initial conditions
ic = ComponentArray(
    car = (
        pos = 0.0,
        vel = 0.0,
    ),
    ∫e = 0.0,
)


## Setup problem and solve
prob = ODEProblem(feedback_car!, ic, (0.0, 20.0), p)
sol = solve(prob)


## Plots
p1 = plot(sol, vars=2, title="Reference Tracking")
scope!(sol, :r)

p2 = scope(sol, [:u, :drag], title="Forces")

p3 = plot(sol, vars=3, title="Errors")
scope!(sol, :e)

plot(p1, p2, p3, layout=(3,1), size=(600,800))