module AMR

export Math, MathML, ExpressionFormula, Unit, Distribution, Observable, Expression,
 Rate, Initial, Parameter, Time,
 StandardUniform, Uniform, StandardNormal, Normal, PointMass,
 Semantic, Header, ODERecord, ODEList, ASKEModel,
 distro_string, amr_to_string

using Reexport
@reexport using MLStyle
@reexport using ACSets
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
end # module end