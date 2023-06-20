# Testing
#########

include("./ASKEMPetriNets.jl")
using AlgebraicPetri
using Catlab.CategoricalAlgebra, Catlab.Graphics
using JSON


#********************
# Petri Net Example *
#********************

# Load a model
askemnet = ASKEMPetriNets.ASKEMPetriNet("../../examples/sir.json")

askemnet.model |> to_graphviz

# Do modifications to the model
askemnet.model[1, :sname] = :M
askemnet.model[1, :tname] = :infect

# Update the properties and JSON with new modifications to structure
ASKEMPetriNets.update!(askemnet)

# Print new JSON
JSON.print(askemnet, 2)

#*****************
# Typing Example *
#*****************
typed_askemnet = ASKEMPetriNets.TypedASKEMPetriNet("../../examples/sir_typed.json")

typed_askemnet.typing |> to_graphviz

@assert is_natural(typed_askemnet.typing)

typed_askemnet.typing.dom[1, :sname] = :M
typed_askemnet.typing.dom[1, :tname] = :infect
typed_askemnet.typing.codom[1, :sname] = :People

# Update the properties and JSON with new modifications to structure
ASKEMPetriNets.update!(typed_askemnet)

# Print new JSON
JSON.print(typed_askemnet, 2)

# Stratification Example
# FIX: This currently doesn't work, potential Catlab bug

using AlgebraicPetri.TypedPetri

sir = typed_askemnet
flux = ASKEMPetriNets.TypedASKEMPetriNet("../../examples/flux_typed.json")

flux.typing |> to_graphviz

@assert is_natural(flux.typing)

augmented_sir = add_reflexives(sir.typing, [[:Strata],[:Strata],[:Strata]], sir.typing.codom)
augmented_flux = add_reflexives(flux.typing, [[:Infect,:Disease],[:Infect,:Disease]], flux.typing.codom)

augmented_sir |> to_graphviz
augmented_flux |> to_graphviz

# stratified = typed_product(augmented_sir, augmented_flux)


#***************
# Span Example *
#***************
sir_flux = ASKEMPetriNets.SpanASKEMPetriNet("../../examples/sir_flux_span.json")
test = Span(sir_flux.legs...)
test.apex |> to_graphviz

sir_flux.legs[1].dom[2,:sname] = :Mzzz
sir_flux.model |> to_graphviz
ASKEMPetriNets.update!(sir_flux)
JSON.print(sir_flux, 2)
