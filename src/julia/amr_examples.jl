module AMRExamples
include("amr.jl")
using .AMR

nomath = Math("")
header = Header("SIR", "amr-schemas:petri_schema.json", "The SIR Model of disease", "petrinet", "0.2")
model = acsetspec(:(LabelledPetriNet{Symbol}), quote
  S(label=:S)
  S(label=:I)
  S(label=:R)

  T(label=:inf)
  T(label=:rec)

  I(is=:S, it=:inf)
  I(is=:I, it=:inf)
  I(is=:I, it=:rec)

  O(os=:I, it=:inf)
  O(os=:I, it=:inf)
  O(os=:R, it=:rec)
end) 

ode = ODERecord([Rate(:inf, ExpressionFormula( "S*I*β", nomath)),
           Rate(:rec, ExpressionFormula("I*γ", nomath))],

          [Initial(:S, ExpressionFormula("S₀", nomath)),
           Initial(:I, ExpressionFormula("I₀", nomath)),
           Initial(:R, ExpressionFormula("R₀", nomath)),],

          [Parameter(:β, "β", "the beta parameter", Unit("1/(persons^2*day)", nomath), 1e-2, Uniform(1e-3, 2e-2)),
          Parameter(:γ, "γ", "the gama parameter", Unit("1/(persons*day)", nomath), 3, Uniform(1, 2e+2)),

          Parameter(:S₀, "S₀", "the initial susceptible population", Unit("persons", nomath), 300000000.0, Uniform(1e6, 4e6)),
          Parameter(:I₀, "I₀", "the initial infected population", Unit("persons", nomath), 1.0, Uniform(1, 1)),
          Parameter(:R₀, "R₀", "the initial recovered population", Unit("persons", nomath), 0.0, Uniform(0, 4)),
          ],
          Time(:t, Unit("day", nomath)))

odelist = ODEList([
  Time(:t, Unit("day", nomath)),
  Parameter(:β, "β", "the beta parameter", Unit("1/(persons^2*day)", nomath), 1e-2, Uniform(1e-3, 2e-2)),
  Rate(:inf, ExpressionFormula("S*I*β", nomath)),

  Parameter(:γ, "γ", "the gama parameter", Unit("1/(persons*day)", nomath), 3, Uniform(1, 2e+2)),
  Rate(:rec, ExpressionFormula("I*γ", nomath)), 

  Parameter(:S₀, "S₀", "the initial susceptible population", Unit("persons", nomath), 300000000.0, Uniform(1e6, 4e6)),
  Initial(:S₀, ExpressionFormula("S₀", nomath)),

  Parameter(:I₀, "I₀", "the initial infected population", Unit("persons", nomath), 1.0, Uniform(1, 1)),
  Initial(:I₀, ExpressionFormula("I₀", nomath)),

  Parameter(:R₀, "R₀", "the initial recovered population", Unit("persons", nomath), 0.0, Uniform(0, 4)),
  Initial(:R₀, ExpressionFormula("R₀", nomath)), 

  ])

amr₁ = ASKEModel(header,
  model,
  [ode]
)

amr₂ = ASKEModel(header,
  model,
  [odelist]
)

println()
println(amr_to_string(amr₁))
println()
println(amr_to_string(amr₂))
end