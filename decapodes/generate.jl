#!/usr/bin/env -S julia --project=. --startup=no --color yes
import Pkg; Pkg.instantiate();
import ACSets.InterTypes: InterTypes, @intertypes, generate_module, PydanticTarget, JSONTarget

JSON_DIR = joinpath((@__DIR__), "json/")
PYTHON_DIR = joinpath((@__DIR__), "python/")

write(PYTHON_DIR * "/intertypes.py", InterTypes.INTERTYPE_PYTHON_MODULE)

@intertypes "intertypes/configuration.it" module DecapodeConfigurations end
using .DecapodeConfigurations
generate_module(DecapodeConfigurations, PydanticTarget, PYTHON_DIR)
generate_module(DecapodeConfigurations, JSONTarget, JSON_DIR)


@intertypes "intertypes/context.it" module DecapodeContexts end
using .DecapodeContexts
generate_module(DecapodeContexts, PydanticTarget, PYTHON_DIR)
generate_module(DecapodeContexts, JSONTarget, JSON_DIR)


@intertypes "intertypes/model.it" module DecapodeModels end
using .DecapodeModels
generate_module(DecapodeModels, PydanticTarget, PYTHON_DIR)
generate_module(DecapodeModels, JSONTarget, JSON_DIR)


@intertypes "intertypes/amr.it" module DecapodesAMR 
  import ..DecapodeConfigurations
  import ..DecapodeContexts
  import ..DecapodeModels
end
using .DecapodesAMR
generate_module(DecapodesAMR, PydanticTarget, PYTHON_DIR)
generate_module(DecapodesAMR, JSONTarget, JSON_DIR)

