module ASKEMDecapodes

export ASKEMDecaExpr, ASKEMDecapode

using ..SyntacticModelsBase
using ..AMR

using StructTypes
using Decapodes
using MLStyle

@data ASKEMDeca <: AbstractTerm begin
  ASKEMDecaExpr(header::AMR.Header, model::Decapodes.DecaExpr)
  ASKEMDecapode(header::AMR.Header, model::Decapodes.SummationDecapode)
end

@doc """    ASKEMDeca

Stores a Decapode with the model metadata for ASKEM AMR conformance.
"""
ASKEMDeca

@doc """    ASKEMDecaExpr

Stores the syntactic expression of a Decapode Expression with the
model metadata for ASKEM AMR conformance.
"""
ASKEMDecaExpr

@doc """    ASKEMDecapode

Stores the combinatorial representation of a Decapode with the
model metadata for ASKEM AMR conformance.
"""
ASKEMDecapode

StructTypes.StructType(::Type{ASKEMDeca}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{ASKEMDeca}) = :_type
StructTypes.subtypes(::Type{ASKEMDeca}) = (ASKEMDecaExpr=ASKEMDecaExpr, ASKEMDecapode=ASKEMDecapode)

SyntacticModelsBase._dict(x::T) where {T<:Union{Decapodes.DecaExpr, Decapodes.Equation, Decapodes.Term}} = begin
  Dict(:_type => typename_last(T), [k=>_dict(getfield(x, k)) for k in fieldnames(T)]...)
end

StructTypes.StructType(::Type{Decapodes.Equation}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{Decapodes.Equation}) = :_type
StructTypes.subtypes(::Type{Decapodes.Equation}) = (Eq=Eq,)

StructTypes.StructType(::Type{Decapodes.Term}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{Decapodes.Term}) = :_type
StructTypes.subtypes(::Type{Decapodes.Term}) = (Var=Decapodes.Var,
  Lit=Decapodes.Lit,
  Judgement=Decapodes.Judgement,
  AppCirc1=Decapodes.AppCirc1,
  App1=Decapodes.App1,
  App2=Decapodes.App2,
  Plus=Decapodes.Plus,
  Mult=Decapodes.Mult,
  Tan=Decapodes.Tan)

end