module ASKEMDecapodes

include("amr.jl")

using Decapodes
using Catlab
using MLStyle

@as_record struct ASKEMDecapode
  header::AMR.Header
  model::Decapodes.DecaExpr
end


h = AMR.Header("harmonic_oscillator",
  "modelreps.io/DecaExpr",
  "A Simple Harmonic Oscillator as a Diagrammatic Equation",
  "DecaExpr",
  "v1.0")

dexpr = Decapodes.parse_decapode(quote
  X::Form0{Point}
  V::Form0{Point}

  k::Constant{Point}

  ∂ₜ(X) == V
  ∂ₜ(V) == -1*k*(X)
end
)

m = ASKEMDecapode(h, dexpr)
end

using JSON
using Decapodes

m = ASKEMDecapodes.m

JSON.print(m, 2)

d = Decapodes.SummationDecapode(m.model)

using ACSets
using ACSets.JSONACSets

JSON.print(generate_json_acset(d),2)

