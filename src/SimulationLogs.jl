module SimulationLogs

using SciMLBase
using RecipesBase

include("types.jl")
include("log.jl")
include("get_log.jl")
include("plot.jl")

const GLOBAL_LOG = Ref(SimulationLog())

export SimulationLog, is_active
export @log
export get_log, scope, scope!

end # module
