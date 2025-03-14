using Documenter
using SimulationLogs

makedocs(
    modules = [SimulationLogs],
    format=Documenter.HTML(
        canonical = "https://jonniedie.github.io/SimulationLogs/stable",
    ),
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "examples/cruise_control.md"
        ],
        "API" => "api.md",
    ],
    repo = "https://github.com/jonniedie/SimulationLogs/blob/{commit}{path}#L{line}",
    sitename = "SimulationLogs Documentation",
    authors = "Jonnie Diegelman",
)

deploydocs(
    repo = "github.com/jonniedie/SimulationLogs.jl.git",
    devbranch = "main",
)
