module ASKEMDecapodes

include("amr.jl")

using Decapodes
using Catlab
using MLStyle

"""    ASKEMDecaExpr

Stores the syntactic expression of a Decapode Expression with the
model metadata for ASKEM AMR conformance.
"""
@as_record struct ASKEMDecaExpr
  header::AMR.Header
  model::Decapodes.DecaExpr
end

"""    ASKEMDecapode

Stores the combinatorial representation of a Decapode with the
model metadata for ASKEM AMR conformance.
"""
@as_record struct ASKEMDecapode
  header::AMR.Header
  model::Decapodes.SummationDecapode
end

# Build the heder object describing the model.

h = AMR.Header("harmonic_oscillator",
  "modelreps.io/DecaExpr",
  "A Simple Harmonic Oscillator as a Diagrammatic Equation",
  "DecaExpr",
  "v1.0")

# The easiest way to write down a DecaExpr is in our DSL and calling the parser.
dexpr = Decapodes.parse_decapode(quote
  X::Form0{Point}
  V::Form0{Point}

  k::Constant{Point}

  ∂ₜ(X) == V
  ∂ₜ(V) == -1*k*(X)
end
)

# Bundle the DecaExpr with the header metadata.
mexpr = ASKEMDecaExpr(h, dexpr)

# Convert a the DecaExpr to a SummationDecapode which is the
# combinatorial representation. The converter lives in Decapodes/src/language.jl.

d = Decapodes.SummationDecapode(mexpr.model)

# We want different metadata for this representation.
# The Summation prefix just means that this decapodes have
# specialized support for the handling of summation.
# The summation operator happens in physics so often,
# that you want to bake in some specialized handling to the data structure.

h = AMR.Header("harmonic_oscillator",
  "modelreps.io/SummationDecapode",
  "A Simple Harmonic Oscillator as a Diagrammatic Equation",
  "SummationDecapode",
  "v1.0")
mpode = ASKEMDecapode(h, d)

end

using JSON
using Decapodes
using ACSets
using ACSets.JSONACSets

m = ASKEMDecapodes.mexpr

# The syntactic representation can be serialized as JSON.
# The resulting structure is like a parse tree of the syntactic
# representation of the DecaExpr
JSON.print(m, 2)

p = ASKEMDecapodes.mpode

# We could also use the JSON serialization built into Catlab
# to serialize the resulting combinatorial representation
JSON.print(generate_json_acset(p.model),2)