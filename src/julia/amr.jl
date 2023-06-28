module AMR

export Math, MathML, ExpressionFormula, Unit, Distribution, Observable, Expression,
 Rate, Initial, Parameter, Time,
 StandardUniform, Uniform, StandardNormal, Normal, PointMass,
 Semantic, Header, ODERecord, ODEList, Typing, ASKEModel,
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
  Typing(system::ACSetSpec, map::Vector{Pair})
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
    StandardUniform   => "U(0,1)"
    Uniform(min, max) => "U($min,$max)"
    StandardNormal    => "N(0,1)"
    Normal(mu, var)   => "N($mu,$var)"
    PointMass(value)  => "δ(value)"
  end
end

function distro_expr(d::Distribution)
  return Base.Meta.parse(distro_string(d))
end

padlines(ss::Vector, n) = map(ss) do s
  " "^n * s
end
padlines(s::String, n=2) = join(padlines(split(s, "\n"), n), "\n")

function amr_to_string(amr)
  @show typeof(amr)
  let ! = amr_to_string
    @match amr begin
      s::String                        => s
      Math(s)                          => !s
      Presentation(s)                  => "<mathml> $s </mathml>"
      u::Unit                          => !u.expression
      d::Distribution                  => distro_string(d)
      Time(id, u)                      => "$id::Time{$(!u)}\n"
      Rate(t, f)                       => "$t::Rate = $(f.expression)"
      Initial(t, f)                    => "$t::Initial = $(f.expression)"
      Observable(id, n, states, f)     => "# $n\n$id::Observable = $(f.expression)($states)\n"
      Header(name, s, d, sn, mv)       => "\"\"\"\nASKE Model Representation: $name$mv :: $sn \n   $s\n\n$d\n\"\"\""
      Parameter(t, n, d, u, v, dist)   => "\n# $n-- $d\n$t::Parameter{$(!u)} = $v ~ $(!dist)\n"
      m::ACSetSpec                     => "Model = begin\n$(padlines(ADTs.to_string(m),2))\nend"
      ODEList(l)                       => "ODE Equations: begin\n" * padlines(join(map(!, l), "\n")) * "\nend"
      ODERecord(rts, init, para, time) => join(vcat(["ODE Record: begin\n"], !rts , !init, !para, [!time, "end"]), "\n")
      vs::Vector{Pair}                 => map(vs) do v; "$(v[1]) => $(v[2])," end |> x-> join(x, "\n") 
      vs::Vector{Semantic}             => join(map(!, vs), "\n\n")
      xs::Vector                       => map(!, xs)
      Typing(system, map)              => "Typing: begin\n$(padlines(!system, 2))\nTypeMap = [\n$(padlines(!map, 2))]\nend"
      ASKEModel(h, m, s)               => "$(!h)\n$(!m)\n\n$(!s)"
    end
  end
end

block(exprs) = begin
  q = :(begin
    
  end)
  append!(q.args, exprs)
  return q
end

extract_acsetspec(s::String) = join(split(s, " ")[2:end], " ") |> Meta.parse

function amr_to_expr(amr)
  @show typeof(amr)
  let ! = amr_to_expr
    @match amr begin
      s::String                        => s
      Math(s)                          => :(Math($(!s)))
      Presentation(s)                  => :(Presentation($(!s)))
      u::Unit                          => u.expression
      d::Distribution                  => distro_expr(d)
      Time(id, u)                      => :($id::Time{$(!u)})
      Rate(t, f)                       => :($t::Rate = $(f.expression))
      Initial(t, f)                    => :($t::Initial = $(f.expression))
      Observable(id, n, states, f)     => begin "$n"; :(@doc $x $id::Observable = $(f.expression)($states)) end
      Header(name, s, d, sn, mv)       => begin x = "ASKE Model Representation: $name$mv :: $sn \n   $s\n\n$d"; :(@doc $x) end
      Parameter(t, n, d, u, v, dist)   => begin x = "$n-- $d"; :(@doc $x  $t::Parameter{$(!u)} = $v ~ $(!dist)) end
      m::ACSetSpec                     => :(Model = begin $(extract_acsetspec(ADTs.to_string(m))) end)
      ODEList(l)                       => :(ODE_Equations = $(block(map(!, l))))
      ODERecord(rts, init, para, time) => :(ODE_Record = (rates=$(!rts), initials=$(!init), parameters=$(!para), time=!time))
      vs::Vector{Pair}                 => begin ys = map(vs) do v; :($(v[1]) => $(v[2])) end; block(ys) end
      vs::Vector{Semantic}             => begin ys = map(!, vs); block(ys) end
      xs::Vector                       => begin ys = map(!, xs); block(ys) end
      Typing(system, map)              => :(Typing = $(!system); TypeMap = $(block(map)))
      ASKEModel(h, m, s)               => :($(!h);$(!m);$(!s))
    end
  end
end
end # module end