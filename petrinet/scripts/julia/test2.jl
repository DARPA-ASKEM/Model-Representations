include("./ASKEMPetriNets.jl")
using AlgebraicPetri
using Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Programs
using JSON

# Load a model
sir_typed = ASKEMPetriNets.to_typed_petri("../../examples/sir_typed.json")

# Read in petri type system
type_sys = sir_typed.model.codom

# Convert to AMR
amr_ont = to_amr(type_sys)
# Read back in model
rt_ont_from_amr = ASKEMPetriNets.extract_petri(amr_ont["model"])
# Check
rt_ont_from_amr == type_sys

# Write out in AMR 
open("test_pn.json","w") do f
    JSON.print(f,amr_ont) 
end
# Read back in
rt_ont_from_file = ASKEMPetriNets.to_petri("test_pn.json")
# Check
rt_ont_from_file.model == type_sys

# Form typed models 
# Write out in AMR 
# Read back in to check 

# Do stratification 
# Write out in AMR 
# Read back in to check 

flux_typed = ASKEMPetriNets.to_typed_petri("../../examples/flux_typed.json")

aug_sir = add_reflexives(sir_typed.model, [[:Strata],[:Strata],[:Strata]], sir_typed.model.codom)
aug_flux = add_reflexives(flux_typed.model, [[:Infect,:Disease],[:Infect,:Disease]], flux_typed.model.codom)

flux_typed.model.codom == sir_typed.model.codom
codom(aug_flux) ==  codom(aug_sir)

# sir_flux = pullback(aug_sir, aug_flux; product_attrs=true)

aug_sir2 = tppn_to_tlpn(aug_sir)
aug_flux2 = tppn_to_tlpn(aug_flux)
sir_flux = pullback(aug_sir2, aug_flux2; product_attrs=true)
  