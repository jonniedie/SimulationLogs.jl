using ComponentArrays
using DifferentialEquations
using SimulationLogs
using Plots; gr()
using UnPack


## Simulation functions
# Simple car with velocity-square drag
function car!(D, vars, p, t; u=0.0)
    @unpack vel = vars
    @unpack c, m = p

    @log drag = c*vel^2

    D.pos = vel
    D.vel = (-drag*sign(vel) + u)/m
end

# Proportional-integral control
function PI!(D, vars, p, t; e)
    @unpack ∫e = vars
    @unpack kp, ki = p

    @log u = kp*e + ki*∫e

    D.∫e = e
    return u
end

# Car with cruise control
function feedback_car!(D, vars, p, t)
    @log r = p.ref(t)
    @log e = r - vars.car.vel

    u = PI!(D.control, vars.control, p.control, t; e=e)
    car!(D.car, vars.car, p.car, t; u)
end


## Inputs
# Parameters
p = (
    ref = t -> 10*(t>1),
    car = (
        m = 1000,
        c = 5,
    ),
    control = (
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
    control = (
        ∫e = 0.0,
    ),
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