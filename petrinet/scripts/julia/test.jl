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

# Stratification Example
# FIX: This currently doesn't work, potential Catlab bug

using AlgebraicPetri.TypedPetri

sir = typed_askemnet
flux = ASKEMPetriNets.to_typed_petri("../../examples/flux_typed.json")

flux.model |> to_graphviz

@assert is_natural(flux.model)

augmented_sir = add_reflexives(sir.model, [[:Strata],[:Strata],[:Strata]], sir.model.codom)
augmented_flux = add_reflexives(flux.model, [[:Infect,:Disease],[:Infect,:Disease]], flux.model.codom)

augmented_sir |> to_graphviz
augmented_flux |> to_graphviz

# stratified = typed_product(augmented_sir, augmented_flux)


#***************
# Span Example *
#***************
#=
function strip_names(p::ACSetTransformation)
    init = NamedTuple([k=>collect(v) for (k,v) in pairs(components(p))])
    homomorphism(strip_names(dom(p)), strip_names(codom(p)), initial=init)
end
  
function strip_names(p::AbstractLabelledPetriNet)
    map(p, Name = name -> nothing)
end
=#

sir_flux = ASKEMPetriNets.to_span_petri("../../examples/sir_flux_span.json")
test = Span(sir_flux.model...)
test.apex |> to_graphviz