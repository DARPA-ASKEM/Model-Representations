module Composites

export CompositeModelExpr, OpenModel, CompositeModel, interface, open_decapode

using MLStyle
using Catlab
using Decapodes

using ..AMR
using ..ASKEMDecapodes
using ..ASKEMUWDs

# @as_record struct OpenModel
#   model::ASKEMDecapodes.ASKEMDecaExpr
#   interface::Vector{Symbol}
# end

# @as_record struct CompositeModel
#   header::AMR.Header
#   composition_pattern::UWDExpr
#   components::Vector{OpenModel}
#   interface::Vector{Symbol}
# end

@data CompositeModel begin
  OpenModel(model::ASKEMDecapodes.ASKEMDecaExpr, interface::Vector{Symbol})
  CompositeModelExpr(header::Header, composition_pattern::UWDExpr, components::Vector{CompositeModel})
end

interface(m::CompositeModel) = @match m begin
  OpenModel(M, I) => I
  CompositeModelExpr(h, uwd, components) => map(ASKEMUWDs.varname, context(uwd))
end

# Extract an open decapode from the decapode expression and the interface
open_decapode(d, interface) = Open(SummationDecapode(d.model), interface)

function Catlab.oapply(m::CompositeModel)
  let ! = oapply
    @match m begin
      # For a primitive model we just attach the interface
      OpenModel(M, I) => open_decapode(M,I)
      # For a composite model, we have to recurse
      CompositeModelExpr(h, pattern, components) => begin
        uwd = ASKEMUWDs.construct(RelationDiagram, pattern)
        Ms = map(m.components) do mᵢ; 
          !(mᵢ) # oapply all the component models recursively
        end
        apex(!(uwd, Ms)) # Then we call the oapply from Decapodes.
      end
    end
  end
end

end