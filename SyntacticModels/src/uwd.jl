module ASKEMUWDs

# include("amr.jl")
export Var, Typed, Untyped, Statement, UWDExpr, UWDTerm

using MLStyle
using Catlab
using Catlab.RelationalPrograms
using Catlab.WiringDiagrams

@data Var begin
  Untyped(var::Symbol)
  Typed(var::Symbol, type::Symbol)
end

@data UWDTerm begin
  # Context(judgements::Vector{Var})
  Statement(relation::Symbol, args::Vector{Var})
  UWDExpr(context::Vector{Var}, statements::Vector{Statement})
end

varname(v::Var) = @match v begin
  Untyped(v) => v
  Typed(v, t) => v
end

vartype(v::Var) = @match v begin
  Typed(v, t) => t
  Untyped(v) => :untyped
end


"""    construct(::Type{RelationDiagram}, ex::UWDExpr)

Builds a RelationDiagram from a UWDExpr like the `@relation` macro does for Julia Exprs.
"""
function construct(::Type{RelationDiagram}, ex::UWDExpr)
  # If you want to understand this code, look at the schema for Relation Diagrams
  # to_graphviz(RelationalPrograms.SchRelationDiagram)
  uwd = RelationDiagram(map(varname, ex.context))
  junctions = Dict()
  # first we add in all the outer ports and make junctions for them.
  for (i,j) in enumerate(ex.context)
    k = add_part!(uwd, :Junction, variable=varname(j), junction_type=vartype(j))
    junctions[varname(j)] = k
    set_subpart!(uwd, i, :outer_junction, k)
  end

  # then for each statement we add a box, and its ports
  for s in ex.statements
    b = add_part!(uwd, :Box, name=s.relation)
    for a in s.args
      # if a junction is missing, we have to add it. This is for nonexported variables
      if !(varname(a) ∈ keys(junctions))
        k = add_part!(uwd, :Junction, variable=varname(a), junction_type=vartype(a))
        junctions[varname(a)] = k
      end
      # every port connects to the junction with the same variable name
      add_part!(uwd, :Port, box=b, port_type=vartype(a), junction=junctions[varname(a)])
    end
  end
  return uwd
end
end
