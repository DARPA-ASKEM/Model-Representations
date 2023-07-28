module Composites

export CompositeModelExpr

using MLStyle
using Catlab
using Decapodes

# include("amr.jl")
# include("decapodes.jl")
# include("uwd.jl")

using ..AMR
using ..ASKEMDecapodes
using ..ASKEMUWDs

@as_record struct CompositeModelExpr
  header::AMR.Header
  composition_pattern::ASKEMUWDs.UWDExpr
  components::Vector{ASKEMDecapodes.ASKEMDecaExpr}
  interfaces::Vector{Vector{Symbol}}
end


function Catlab.oapply(m::Composites.CompositeModelExpr)
  open(d, interface) = Open(SummationDecapode(d.model), interface)
  # First we have to construct the decapode from the decaexpr
  uwd = ASKEMUWDs.construct(RelationDiagram, m.composition_pattern)
  # Then we attach interfaces to the components
  Ms = map(zip(m.components, m.interfaces)) do p; open(p...) end
  # Then we call the oapply from Decapodes.
  return oapply(uwd, Ms)
end

end