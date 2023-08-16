# module ASKEMDecapodesExamples

using ..SyntacticModels
using ..SyntacticModels.ASKEMDecapodes
using ..SyntacticModels.AMR

using MLStyle
using JSON
using Catlab
using ACSets
using ACSets.JSONACSets
using Decapodes
using Test

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


# The syntactic representation can be serialized as JSON.
# The resulting structure is like a parse tree of the syntactic
# representation of the DecaExpr
write_json_model(mexpr)

# We could also use the JSON serialization built into Catlab
# to serialize the resulting combinatorial representation
sm_write_json_acset(mpode.model, "$(mpode.header.name)-acset")
# end


 # Can we read back the models we just wrote?
@testset "Decapodes Readback" begin
  mexpr′ = readback(mexpr)
  @test JSON3.write(mexpr) == JSON3.write(mexpr′)
end