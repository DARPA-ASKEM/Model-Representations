module AMR
using MLStyle
using ACSets
using ACSets.ADTs
using ACSets.ACSetInterface

@data MathML begin
  Math(String)
  Presentation(String)
end

@as_record struct ExpressionFormula{T}
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

@as_record struct Observable{T}
  id::Symbol
  name::String
  states::Vector{Symbol}
  f::ExpressionFormula
end

@data Expression begin
  Rate(target::Symbol, f::ExpressionFormula)
  Initial(target::Symbol, f::ExpressionFormula)
  Parameter(id::Symbol, name::String, description::String, units::Unit, value::Float64, distribution::Distribution)
  Time(id::Symbol, units::Unit)
end

@data Semantic begin
  ODEList(statements::Vector{Expression})
  ODERecord(rates::Vector{Rate}, initials::Vector{Initial}, parameters::Vector{Parameter}, time::Time)
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

function distro_string(d::Distribution)
  @match d begin
    StandardUniform => "U(0,1)"
    Uniform(min, max) => "U($min,$max)"
    StandardNormal => "N(0,1)"
    Normal(mu, var) => "N($mu,$var)"
    PointMass(value) => "δ(value)"
  end
end

function amr_to_string(amr)
  let ! = amr_to_string
    @match amr begin
      s::String       => s
      Math(s)         => !s
      Presentation(s) => "<mathml> $s </mathml>"
      u::Unit         => !u.expression
      d::Distribution => distro_string(d)
      Rate(t, f)      => "$t::Rate = $(f.expression)"
      Initial(t, f)      => "$t::Initial = $(f.expression)"
      Parameter(t, name, desc, units, value, distr)      => "\n# $name -- $desc\n$t::Parameter{$(!units)} = $value ~ $(!distr)\n"
      Observable(id, name, states, f) => "# $name\n$id::Observable = $(f.expression)($states)\n"
      Time(id, u) => "$id::Time{$(!u)}\n"
      Header(name, s, d, sn, mv) => "\"\"\"\nASKE Model Representation: $name@v$mv :: $sn \n   $s\n\n$d\n\"\"\""
      m::ACSetSpec => "Model = quote\n$(ADTs.to_string(m))\nend"
      vs::Vector{Semantic} => join(map(!, vs), "\n")
      xs::Vector => map(!, xs)
      ODEList(l) => "ODE Equations: begin\n" * join(map(!, l), "\n") * "\nend"
      ODERecord(rates, initials, parameters, time) => join(vcat(["ODE Record: begin\n"], !rates , !initials, !parameters, [!time, "end"]), "\n")
      ASKEModel(h, m, s) => "$(!h)\n$(!m)\n\n$(!s)"
    end
  end
end

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
println(amr_to_string(amr₂))
end # module end