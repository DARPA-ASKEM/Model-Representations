module ASKEMDecapodes

export ASKEMDecaExpr, ASKEMDecapode

using ..AMR

using Decapodes
using Catlab
using MLStyle

"""    ASKEMDecaExpr

Stores the syntactic expression of a Decapode Expression with the
model metadata for ASKEM AMR conformance.
"""
struct ASKEMDecaExpr
  header::AMR.Header
  model::Decapodes.DecaExpr
end

@as_record ASKEMDecaExpr

"""    ASKEMDecapode

Stores the combinatorial representation of a Decapode with the
model metadata for ASKEM AMR conformance.
"""
struct ASKEMDecapode
  header::AMR.Header
  model::Decapodes.SummationDecapode
end

@as_record ASKEMDecapode

end