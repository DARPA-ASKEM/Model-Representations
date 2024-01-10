#!/usr/bin/env -S julia --project="@askem" --startup=no --color yes -J/home/five/.julia/environments/askem/ASKEM-Sysimage.so
# This script expects an installation of the Standard ASKEM Julia Environment: `https://github.com/DARPA-ASKEM/askem-julia`
# TODO: Create and use project environment for this specific repo
import ACSets.InterTypes: InterTypes, @intertypes, generate_module, PydanticTarget, JSONTarget

PYTHON_DIR = joinpath((@__DIR__), "lib/")
FRAMEWORKS = ["decapodes"]

@intertypes "base.it" module AMRBase end
using .AMRBase
generate_module(AMRBase, PydanticTarget, PYTHON_DIR)
write(PYTHON_DIR * "/intertypes.py", InterTypes.INTERTYPE_PYTHON_MODULE)



# TODO: Loop over all frameworks when they have `.it` files
@intertypes "decapodes.it" module DecapodesAMR 
  import ..AMRBase
end
using .DecapodesAMR
DECAPODES_DIR = joinpath((@__DIR__), "decapodes")
generate_module(DecapodesAMR, JSONTarget, DECAPODES_DIR)  
generate_module(DecapodesAMR, PydanticTarget, PYTHON_DIR)
