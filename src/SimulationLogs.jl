"""
    SimulationLogs

Log internal variables in a DifferentialEquations.jl simulation with the `@log` macro and
use the `get_log` function to retrieve the logged variables.
"""
module SimulationLogs

using DiffEqBase: CallbackSet, DiscreteCallback, ContinuousCallback, isinplace, solve
using RecipesBase: RecipesBase, @recipe, @series, @userplot
using SciMLBase: AbstractTimeseriesSolution, remake

include("types.jl")
include("macros.jl")
include("logging.jl")
include("plotting.jl")

const GLOBAL_LOG = SimulationLog()

export SimulationLog, is_active, value_dict
export Logged
export @log
export get_log, logged_solve, scope, scope!

end # module
