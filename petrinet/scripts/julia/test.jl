# Testing
#########

include("./ASKEMPetriNets.jl")
using .ASKEMPetriNets

using AlgebraicPetri
using Catlab
using JSON

# Load a model
askemnet = ASKEMPetriNet("../../examples/sir.json")

model(askemnet) |> to_graphviz

# Do modifications to the model
askemnet.model[1, :sname] = :M
askemnet.model[1, :tname] = :infect

# Update the properties and JSON with new modifications to structure
update!(askemnet)

# Print new JSON
JSON.print(askemnet, 2)

typed_askemnet = TypedASKEMPetriNet("../../examples/sir_typed.json")

model(typed_askemnet) |> to_graphviz
typed_model(typed_askemnet) |> to_graphviz

@assert is_natural(typed_askemnet.model)

typed_askemnet.model.dom[1, :sname] = :M
typed_askemnet.model.dom[1, :tname] = :infect
typed_askemnet.model.codom[1, :sname] = :People

# Update the properties and JSON with new modifications to structure
update!(typed_askemnet)

# Print new JSON
JSON.print(typed_askemnet, 2)

# Stratification

sir = TypedASKEMPetriNet("../../examples/sir_typed_aug.json")
flux = TypedASKEMPetriNet("../../examples/flux_typed_aug.json")

sir_flux = StratifiedASKEMPetriNet(sir, flux)

model(sir_flux) |> to_graphviz
typed_model(sir_flux) |> to_graphviz

JSON.print(sir_flux, 2)
