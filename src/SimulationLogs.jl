module SimulationLogs

using SciMLBase

include("log.jl")
include("sim_log.jl")

const GLOBAL_LOG = Ref(SimulationLog())

export SimulationLog, is_active
export @log
export extract

end # module
