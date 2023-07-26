module ASKEMDecapodes

include("amr.jl")

using Decapodes
using Catlab
using MLStyle

@as_record struct ASKEMDecapode
  header::AMR.Header
  model::Decapodes.DecaExpr
end


h = AMR.Header("diffusion",
  "modelreps.io/DEC",
  "The diffusion equation in DEC",
  "DEC",
  "v1.0")

dexpr = Decapodes.parse_decapode(quote
  X::Form0
  V::Form0

  k::Constant

  ∂ₜ(X) == V
  ∂ₜ(V) == -1*k*(X)
end
)

m = ASKEMDecapode(h, dexpr)
end

using JSON
using Decapodes
JSON.print(ASKEMDecapodes.m, 2)