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
  Dict(:_type => T, [k=>_dict(getfield(x, k)) for k in fieldnames(T)]...)
end


end