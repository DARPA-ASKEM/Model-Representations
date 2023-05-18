# Testing
#########

include("./ASKEMPetriNets.jl")
using AlgebraicPetri
using Catlab.CategoricalAlgebra, Catlab.Graphics
using JSON

# Load a model
askemnet = ASKEMPetriNets.to_petri("../../examples/sir.json")

askemnet.model |> to_graphviz

# Do modifications to the model
askemnet.model[1, :sname] = :M
askemnet.model[1, :tname] = :infect

# Update the properties and JSON with new modifications to structure
ASKEMPetriNets.update!(askemnet)

# Print new JSON
JSON.print(askemnet, 2)

typed_askemnet = ASKEMPetriNets.to_typed_petri("../../examples/sir_typed.json")

typed_askemnet.model |> to_graphviz

@assert is_natural(typed_askemnet.model)

typed_askemnet.model.dom[1, :sname] = :M
typed_askemnet.model.dom[1, :tname] = :infect
typed_askemnet.model.codom[1, :sname] = :People

# Update the properties and JSON with new modifications to structure
ASKEMPetriNets.update!(typed_askemnet)

# Print new JSON
JSON.print(typed_askemnet, 2)
