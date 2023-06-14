include("./ASKEMPetriNets.jl")
using AlgebraicPetri
using Catlab.CategoricalAlgebra, Catlab.Graphics, Catlab.Programs
using JSON

# Load a model
sir_typed = ASKEMPetriNets.to_typed_petri("../../examples/sir_typed.json")

# Read in petri type system
type_sys = sir_typed.model.codom


amr_ont = to_amr(type_sys)
rt_ont_from_amr = ASKEMPetriNets.extract_petri(amr_ont["model"])
rt_ont_from_amr == type_sys

open("test_pn.json","w") do f
    JSON.print(f,amr_ont) 
end
rt_ont_from_file = ASKEMPetriNets.to_petri("test_pn.json")
rt_ont_from_file.model == type_sys

# Write out in AMR 
# Read back in to check

# Form typed models 
# Write out in AMR 
# Read back in to check 

# Do stratification 
# Write out in AMR 
# Read back in to check 
