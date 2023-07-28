using ..SyntacticModels.AMR
using ..SyntacticModels.ASKEMDecapodes
using ..SyntacticModels.ASKEMUWDs
using ..SyntacticModels.Composites

using MLStyle
using JSON
using Decapodes
using Catlab
using Catlab.RelationalPrograms
using Catlab.WiringDiagrams



x = Typed(:X, :Form0)
v = Typed(:V, :Form0)
Q = Typed(:Q, :Form0)

c = [x, Q]
s = [Statement(:oscillator, [x,v]),
  Statement(:heating, [v,Q])]
u = ASKEMUWDs.UWDExpr(c, s)



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

# That gave us the first model
d1 = ASKEMDecaExpr(h, dexpr)

# The second model is:
d2 = ASKEMDecaExpr(
  AMR.Header("fricative_heating",
   "modelreps.io/SummationDecapode",
   "Velocity makes it get hot, but you dissipate heat away from Q₀",
   "SummationDecapode", "v1.0"),
    Decapodes.parse_decapode(quote
      V::Form0{Point}
      Q::Form0{Point}
      κ::Constant{Point}
      λ::Constant{Point}
      Q₀::Parameter{Point}

      ∂ₜ(Q) == κ*V + λ(Q - Q₀)
    end)
)

# Now we can assemble this bad boi:
h = AMR.Header("composite_physics", "modelreps.io/Composite", "A composite model", "CompositeModelExpr", "v0.0")
m = CompositeModelExpr(h, u, [OpenModel(d1, [:X, :Ẋ]), OpenModel(d2, [:V, :Q])])
interface(m) == [:X, :Q]
write_json_model(m) # you can see from this little model (two coupled odes even) that the jsons will not be human editable. 

# now we can interpret this big data structure to execute a composition!
composite = oapply(m)
display(composite)
to_graphviz(composite)
sm_write_json_acset(composite,"$(m.header.name)-acset")