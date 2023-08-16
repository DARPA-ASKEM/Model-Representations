module ASKEMUWDs

# include("amr.jl")
export Var, Typed, Untyped, Statement, UWDExpr, UWDModel, UWDTerm, context

using ..SyntacticModelsBase
using ..AMR

using MLStyle
using StructTypes
using Catlab
using Catlab.RelationalPrograms
using Catlab.WiringDiagrams


@data Var <: AbstractTerm begin
  Untyped(var::Symbol)
  Typed(var::Symbol, type::Symbol)
end

@doc """    Var

Variables of a UWD. Types are the domain types, ScalarField, VectorField, Dual1Form, Primal2Form NOT Float64,Complex128
"""
Var

StructTypes.StructType(::Type{Var}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{Var}) = :_type
StructTypes.subtypes(::Type{Var}) = (Untyped=Untyped, Typed=Typed)

@data UWDTerm <: AbstractTerm begin
  Statement(relation::Symbol, variables::Vector{Var})
  UWDExpr(context::Vector{Var}, statements::Vector{Statement})
  UWDModel(header::AMR.Header, uwd::UWDExpr)
end

@doc """    UWDTerm

Term specifying UWD.

- UWDModel: A header and UWD Expr
- UWDExpr: A Context of variables and a list of statements defining a UWD
- Statement: R(x,y,z) a relation that acts on its arguments (which are Vars)
"""
UWDTerm

StructTypes.StructType(::Type{UWDTerm}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{UWDTerm}) = :_type
StructTypes.subtypes(::Type{UWDTerm}) = (Statement=Statement, UWDExpr=UWDExpr, UWDModel=UWDModel)

varname(v::Var) = @match v begin
  Untyped(v) => v
  Typed(v, t) => v
end

vartype(v::Var) = @match v begin
  Typed(v, t) => t
  Untyped(v) => :untyped
end

context(t::UWDTerm) = @match t begin
  Statement(R, xs) => xs
  UWDExpr(context, statements) => context
  UWDModel(h, uwd) => context(uwd)
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
    for a in s.variables
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

# construct(t::Type{RelationDiagram}, ex::UWDModel) = construct(t, ex.uwd)