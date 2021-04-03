# SimulationLogs.jl

SimulationLogs lets you log variables from within a DifferentialEquations.jl ODE simulation.

## The Basics

To log a variable, use the `@log` macro before an existing variable declaration in the simulation. The syntax for this looks like:
```julia
@log x = u[1]+u[3]
```

To log an expression to an output variable without creating that variable in the simulation use the following syntax:
```julia
@log x u[1]+u[3]
```

To extract logged values from a simulation, use the `get_log` function.