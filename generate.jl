#!/usr/bin/env -S julia --project="@askem" --startup=no --color yes -J/home/five/.julia/environments/askem/ASKEM-Sysimage.so
# This script expects an installation of the Standard ASKEM Julia Environment: `https://github.com/DARPA-ASKEM/askem-julia`
# TODO: Create and use project environment for this specific repo
import ACSets.InterTypes: InterTypes, @intertypes, generate_python_module, generate_jsonschema_module

PYTHON_DIR = (@__DIR__) * "/lib/"
FRAMEWORKS = ["decapodes"]

@intertypes "base.it" module AMRBase end
using .AMRBase
generate_python_module(AMRBase, PYTHON_DIR)
write(PYTHON_DIR * "/intertypes.py", InterTypes.INTERTYPE_PYTHON_MODULE)



# TODO: Loop over all frameworks when they have `.it` files
# NOTE: Python module naming generates an immutable module name from path so I have to put `decapodes.it` in the root of the project
# Ideally, I'd put it in `./decapodes/decapodes.it` instead
# The code that needs to be fixed is here: https://github.com/AlgebraicJulia/ACSets.jl/blob/813a4e1e8eca5639df639d119f6a2748f5c51aff/src/intertypes/python.jl#L159-L161
@intertypes "decapodes.it" module DecapodesAMR 
  import ..AMRBase
end
using .DecapodesAMR
generate_jsonschema_module(DecapodesAMR, (@__DIR__) * "decapodes")  
# NOTE: `path` is an ignored argument see https://github.com/AlgebraicJulia/ACSets.jl/blob/813a4e1e8eca5639df639d119f6a2748f5c51aff/src/intertypes/json.jl#L362
mv("decapodes_schema.json", "decapodes/decapodes_schema.json")
generate_python_module(DecapodesAMR, PYTHON_DIR)
