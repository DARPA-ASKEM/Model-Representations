include("./ASKEMPetriNets.jl")
using AlgebraicPetri
using AlgebraicPetri.TypedPetri
using Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Programs
using JSON

# Load a model
sir_typed = ASKEMPetriNets.TypedASKEMPetriNet("../../examples/sir_typed_aug.json")

# Read in petri type system
type_sys = sir_typed.typing.codom

# Convert to AMR
amr_ont = ASKEMPetriNets.form_amr(type_sys)
# Read back in model
rt_ont_from_amr = ASKEMPetriNets.extract_petri(amr_ont["model"])
# Check
rt_ont_from_amr == type_sys

# Write out in AMR 
open("test_pn.json","w") do f
  JSON.print(f,amr_ont) 
end
# Read back in
rt_ont_from_file = ASKEMPetriNets.ASKEMPetriNet("test_pn.json")
# Check
rt_ont_from_file.model == type_sys

# Form typed models 
# Write out in AMR 
# Read back in to check 

# Do stratification 
# Write out in AMR 
# Read back in to check 

flux_typed = ASKEMPetriNets.TypedASKEMPetriNet("../../examples/flux_typed_aug.json")

# aug_sir = add_reflexives(sir_typed.model, [[:Strata],[:Strata],[:Strata]], sir_typed.model.codom)
# aug_flux = add_reflexives(flux_typed.model, [[:Infect,:Disease],[:Infect,:Disease]], flux_typed.model.codom)

flux_typed.typing.codom == sir_typed.typing.codom
# codom(aug_flux) ==  codom(aug_sir)

aug_sir2 = ASKEMPetriNets.tppn_to_tlpn(sir_typed.typing)
aug_flux2 = ASKEMPetriNets.tppn_to_tlpn(flux_typed.typing)
sir_flux = pullback(aug_sir2, aug_flux2; product_attrs=true)


compose(first(legs(sir_flux)),aug_sir2) |> to_graphviz

first(legs(sir_flux)) |> to_graphviz

#amr_stratified = ASKEMPetriNets.form_amr(apex(sir_flux))

prop_apex = ASKEMPetriNets.lpn_to_ppn(flatten_labels(apex(sir_flux)))
apex_typed = compose(first(legs(sir_flux)),aug_sir2)
prop_apex_typed = ASKEMPetriNets.tlpn_to_tppn(flatten_labels(apex_typed))
prop_legs = Vector{ACSetTransformation}()
for tpn in legs(sir_flux)
  push!(prop_legs,ASKEMPetriNets.tlpn_to_tppn(flatten_labels(tpn)))
end

amr_strat = ASKEMPetriNets.form_amr(prop_apex,prop_apex_typed,prop_legs)
# amr_strat["semantics"]["stratification"]["typing"]["system"] = sir_typed.json["semantics"]["typing"]["system"]
amr_strat["semantics"]["stratification"]["typing"]["system"] = ASKEMPetriNets.form_amr(type_sys)
amr_strat["semantics"]["stratification"]["span"][1]["system"] = sir_typed.json
amr_strat["semantics"]["stratification"]["span"][2]["system"] = flux_typed.json
open("test_strat.json","w") do f
  JSON.print(f,amr_strat,2) 
end
# rt_amr_from_file = ASKEMPetriNets.to_stratification("test_strat.json")
rt_amr_from_file = ASKEMPetriNets.StratifiedASKEMPetriNet("test_strat.json")

prop_apex == rt_amr_from_file.model
