module AMR
using MLStyle
using ACSets
using ACSets.ADTs
using ACSets.ACSetInterface

@data MathML begin
  Math(String)
  Presentation(String)
end

@as_record struct ExpressionValue{T}
  target::Symbol
  expression::T
  expression_mathml::MathML
end

@as_record struct Unit
  expression::String
  expression_mathml::MathML
end

@data Distribution begin
  StandardUniform
  Uniform(min, max)
  StandardNormal
  Normal(mean, variance)
  PointMass(value)
end

# @as_record struct Parameter
#   id::Symbol
#   name::String
#   description::String
#   units::Unit
#   value::Float64
#   distribution::Distribution
# end

@as_record struct Observable{T}
  id::Symbol
  name::String
  states::Vector{Symbol}
  expression::T
  expression_mathml::MathML
end

# @as_record struct Time
#   id::Symbol
#   units::Unit
# end

@data Expression begin
  Rate(ExpressionValue)
  Initial(ExpressionValue)
  Parameter(id::Symbol, name::String, description::String, units::Unit, value::Float64, distribution::Distribution)
  Time(id::Symbol, units::Unit)
end

@data Semantic begin
  ODE(rates::Vector{ExpressionValue}, initials::Vector{ExpressionValue}, parameters::Vector{Parameter}, time::Time)
  ODEList(statements::Vector{Expression})
  # Metadata
  # Typing
  # Stratification
end

@as_record struct Header
  name::String
  schema::String
  description::String
  schema_name::String
  model_version::String
end

@as_record struct ASKEModel
  header::Header 
  model::ACSetSpec
  semantics::Vector{Semantic}
end

nomath = Math("")
header = Header("SIR", "amr-schemas:petri_schema.json", "The SIR Model of disease", "petrinet", "v0.2")
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


ode = ODE([ExpressionValue(:inf, "S*I*β", nomath),
           ExpressionValue(:rec, "I*γ", nomath)],

          [ExpressionValue(:S, "S₀", nomath),
           ExpressionValue(:I, "I₀", nomath),
           ExpressionValue(:R, "R₀", nomath),],

          [Parameter(:β, "β", "the beta parameter", Unit("1/(persons^2*day)", nomath), 1e-2, Uniform(1e-3, 2e-2)),
          Parameter(:γ, "γ", "the gama parameter", Unit("1/(persons*day)", nomath), 3, Uniform(1, 2e+2)),

          Parameter(:S₀, "S₀", "the initial susceptible population", Unit("persons", nomath), 300000000.0, Uniform(1e6, 4e6)),
          Parameter(:I₀, "I₀", "the initial infected population", Unit("persons", nomath), 1.0, Uniform(1, 1)),
          Parameter(:R₀, "R₀", "the initial recovered population", Unit("persons", nomath), 0.0, Uniform(0, 4)),
          ],
          Time(:t, Unit("day", nomath)))

amr = ASKEModel(header,
  model,
  [ode]
)

println(to_string(amr.model))
println(amr.semantics[1])
end