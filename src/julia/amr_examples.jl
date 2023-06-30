module AMRExamples
include("amr.jl")
using .AMR
using Test

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

typesystem = acsetspec(:(LabelledPetriNet{Symbol}), quote
  S(label=:Pop)

  T(label=:inf)
  T(label=:disease)
  T(label=:strata)

  I(is=:Pop, it=:inf)
  I(is=:Pop, it=:inf)
  I(is=:Pop, it=:disease)
  I(is=:Pop, it=:strata)

  O(os=:Pop, it=:inf)
  O(os=:Pop, it=:inf)
  O(os=:Pop, it=:disease)
  O(os=:Pop, it=:strata)
end) 


typing = Typing(
  typesystem,
  [
    (:S=>:Pop),
    (:I=>:Pop),
    (:R=>:Pop),
    (:inf=>:inf),
    (:rec=>:disease)
  ]
)

amr₂ = ASKEModel(header,
  model,
  [
    odelist,
    typing
  ]
)

println()
println(amr_to_string(amr₁))
println()
println(amr_to_string(amr₂))

AMR.amr_to_expr(amr₁) |> println
AMR.amr_to_expr(amr₂.header) |> println
AMR.amr_to_expr(amr₂.model) |> println
map(AMR.amr_to_expr(amr₂.semantics[1]).args[2].args) do s; println(s) end
AMR.amr_to_expr(amr₂.semantics[1]).args[2]
AMR.amr_to_expr(amr₂.semantics[1])
AMR.amr_to_expr(amr₂) |> println

h = AMR.load(Header, Dict("name" => "SIR Model",
"schema" => "https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/petrinet_v0.5/petrinet/petrinet_schema.json",
"description" => "SIR model",
"schema_name" => "petrinet",
"model_version" => "0.1"))  

@test AMR.amr_to_string(h) == "\"\"\"\nASKE Model Representation: SIR Model0.1 :: petrinet \n   https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/petrinet_v0.5/petrinet/petrinet_schema.json\n\nSIR model\n\"\"\"" 

mjson = raw"""{
    "states": [
      {
        "id": "S",
        "name": "Susceptible",
        "description": "Number of individuals that are 'susceptible' to a disease infection",
        "grounding": {
          "identifiers": {
            "ido": "0000514"
          }
        },
        "units": {
          "expression": "person",
          "expression_mathml": "<ci>person</ci>"
        }
      },
      {
        "id": "I",
        "name": "Infected",
        "description": "Number of individuals that are 'infected' by a disease",
        "grounding": {
          "identifiers": {
            "ido": "0000511"
          }
        },
        "units": {
          "expression": "person",
          "expression_mathml": "<ci>person</ci>"
        }
      },
      {
        "id": "R",
        "name": "Recovered",
        "description": "Number of individuals that have 'recovered' from a disease infection",
        "grounding": {
          "identifiers": {
            "ido": "0000592"
          }
        },
        "units": {
          "expression": "person",
          "expression_mathml": "<ci>person</ci>"
        }
      }
    ],
    "transitions": [
      {
        "id": "inf",
        "input": [
          "S",
          "I"
        ],
        "output": [
          "I",
          "I"
        ],
        "properties": {
          "name": "Infection",
          "description": "Infective process between individuals"
        }
      },
      {
        "id": "rec",
        "input": [
          "I"
        ],
        "output": [
          "R"
        ],
        "properties": {
          "name": "Recovery",
          "description": "Recovery process of a infected individual"
        }
      }
    ]
  }
  """
using JSON
modeldict = JSON.parse(mjson)
using ACSets.ADTs

AMR.petrispec(modeldict) |> ACSets.ADTs.to_string |> println

semantics_str = raw"""{
  "ode": {
    "rates": [
      {
        "target": "inf",
        "expression": "S*I*beta",
        "expression_mathml": "<apply><times/><ci>S</ci><ci>I</ci><ci>beta</ci></apply>"
      },
      {
        "target": "rec",
        "expression": "I*gamma",
        "expression_mathml": "<apply><times/><ci>I</ci><ci>gamma</ci></apply>"
      }
    ],
    "initials": [
      {
        "target": "S",
        "expression": "S0",
        "expression_mathml": "<ci>S0</ci>"
      },
      {
        "target": "I",
        "expression": "I0",
        "expression_mathml": "<ci>I0</ci>"
      },
      {
        "target": "R",
        "expression": "R0",
        "expression_mathml": "<ci>R0</ci>"
      }
    ],
    "parameters": [
      {
        "id": "beta",
        "name": "β",
        "description": "infection rate",
        "units": {
          "expression": "1/(person*day)",
          "expression_mathml": "<apply><divide/><cn>1</cn><apply><times/><ci>person</ci><ci>day</ci></apply></apply>"
        },
        "value": 2.7e-7,
        "distribution": {
          "type": "StandardUniform1",
          "parameters": {
            "minimum": 2.6e-7,
            "maximum": 2.8e-7
          }
        }
      },
      {
        "id": "gamma",
        "name": "γ",
        "description": "recovery rate",
        "grounding": {
          "identifiers": {
            "askemo": "0000013"
          }
        },
        "units": {
          "expression": "1/day",
          "expression_mathml": "<apply><divide/><cn>1</cn><ci>day</ci></apply>"
        },
        "value": 0.14,
        "distribution": {
          "type": "StandardUniform1",
          "parameters": {
            "minimum": 0.1,
            "maximum": 0.18
          }
        }
      },
      {
        "id": "S0",
        "name": "S₀",
        "description": "Total susceptible population at timestep 0",
        "value": 1000
      },
      {
        "id": "I0",
        "name": "I₀",
        "description": "Total infected population at timestep 0",
        "value": 1
      },
      {
        "id": "R0",
        "name": "R₀",
        "description": "Total recovered population at timestep 0",
        "value": 0
      }
    ],
    "observables": [
      {
        "id": "noninf",
        "name": "Non-infectious",
        "states": [
          "S",
          "R"
        ],
        "expression": "S+R",
        "expression_mathml": "<apply><plus/><ci>S</ci><ci>R</ci></apply>"
      }
    ],
    "time": {
      "id": "t",
      "units": {
        "expression": "day",
        "expression_mathml": "<ci>day</ci>"
      }
    }
  }
}
"""
semantics_dict = JSON.parse(semantics_str)
@show semantics_dict

AMR.load(ODERecord, semantics_dict["ode"]) |> AMR.amr_to_string |> println

sirmodel_dict = JSON.parsefile(joinpath([@__DIR__, "..", "..", "petrinet", "examples", "sir.json"]))
AMR.optload(AMRExamples.sirmodel_dict, ["model", :states], nothing) |> show
sirmodel = AMR.load(ASKEModel, sirmodel_dict) 
sirmodel |> AMR.amr_to_string |> println

sirmodel_dict = JSON.parsefile(joinpath([@__DIR__, "..", "..", "petrinet", "examples", "sir_typed.json"]))
semtyp = sirmodel_dict["semantics"]["typing"]

sirmodel = AMR.load(Typing, semtyp) |> AMR.amr_to_string |> println

sirmodel = AMR.load(ASKEModel, sirmodel_dict) 
sirmodel |> AMR.amr_to_string |> println
end