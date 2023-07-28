include("../src/SyntacticModels.jl")

using .SyntacticModels

using Test

write_json_model(m, prefix=joinpath(@__DIR__, "json")) = open(joinpath(prefix, "$(m.header.name).json"), "w") do fp
  JSON.print(fp, m, 2)
end

sm_write_json_acset(X, fname, prefix=joinpath(@__DIR__, "json")) = open(joinpath(prefix, "$(fname).json"), "w") do fp
  JSON.print(fp, generate_json_acset(X), 2)
end

try
  mkdir(joinpath(@__DIR__, "json"))
catch
  @info "JSON DIR already exists, you might want to rm -r it to clean up"
end

include("amr_examples.jl")
include("decapodes_examples.jl")
include("uwd_examples.jl")
include("composite_models_examples.jl")