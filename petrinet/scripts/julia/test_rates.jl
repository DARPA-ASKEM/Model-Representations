# Testing
#########

include("./ASKEMPetriNets.jl")
using .ASKEMPetriNets

using AlgebraicPetri, AlgebraicPetri.TypedPetri
using Catlab
using JSON

import .ASKEMPetriNets: form_typing_semantics 

# Load a model
ont_pop_vax = ASKEMPetriNet("../../examples/ont_pop_vax.json")
flux_typed = TypedASKEMPetriNet("../../examples/flux_typed_aug.json")

s1mira = ASKEMPetriNet("./scenario1_a.json")

s1mira_uwd = @relation () where {(S::Pop, I::Pop, E::Pop, R::Pop, D::Pop)} begin
  Infect(S, I, E, I)
  Disease(E, I)
  Disease(I, R)
  Disease(I, D)
  Strata(S,S)
  Strata(E,E)
  Strata(I,I)
  Strata(R,R)  
end

s1mira_act = oapply_typed(LabelledPetriNet(ont_pop_vax.model), s1mira_uwd, [:t1, :t2, :t3, :t4, :rflx_S, :rflx_I, :rflx_E, :rflx_R])

s1mira.json["semantics"]["typing"] = form_typing_semantics(s1mira_act)
s1mira.json["semantics"]["typing"]["system"] = ont_pop_vax.json

for (ii, s) in enumerate(s1mira.model[:sname])
  if s != :D
    t = add_transition!(s1mira.model;tname=Symbol("rflx_"*String(s)))
    i = add_input!(s1mira.model,t,ii)
    o = add_output!(s1mira.model,t,ii)
  end
end
for ii in 5:8
  s1mira.model[ii,:tprop] = Dict{String,Any}()
  s1mira.model[ii,:tprop]["output"] = [""]
  s1mira.model[ii,:tprop]["input"] = [""]
  s1mira.model[ii,:tprop]["id"] = ""
  s1mira.model[ii,:tprop]["properties"] = Dict{String,Any}("name"=>"")
end
update!(s1mira)

s1mira_typed = TypedASKEMPetriNet(s1mira)

s1mira_flux = StratifiedASKEMPetriNet(s1mira_typed, flux_typed)

model(s1mira_flux) |> to_graphviz
typed_model(s1mira_flux) |> to_graphviz

s1mira_flux.json["semantics"]

s1mira_typed.json["semantics"]["ode"]

#******************************************************************
# Functions to derive optional rates/values for stratified models *
#******************************************************************

function form_rates(pb::ACSetLimit,ps::AbstractVector{TypedASKEMPetriNet};binop="*")
  # Possibly have input vector of which leg to use
  # Or operation to apply with default being "*"
  # Or dict of transition types from type system
  # maybe have scale option 
  strat_mdl = pb(apex)
  rates = Vector{Any}()
  for ii in 1:nt(strat_apex)
    # Dict{String,Any}
  end
end

# parameters --> concatenate
# time --> ?
# observables --> ?
# initials 
# rates 

function form_initial_values(pb::ACSetLimit,ps::AbstractVector{TypedASKEMPetriNet};binop="*")
  inits = Vector{Any}()
end

function form_ode_semantics(strat::StratifiedASKEMPetriNet)
  semantics = Dict{String,Any}()
  semantics["parameters"] = Vector{Any}()
  for ii in 1:length(legs(strat.model))
    foot = ASKEMPetriNet(strat.json["semantics"]["span"][ii]["system"])
    println(ii)
    if "parameters" in keys(foot.json["semantics"]["ode"])
      push!(semantics["parameters"],foot.json["semantics"]["ode"]["parameters"]...)
    end
  end
end


import AlgebraicPetri.TypedPetri: oapply_typed

function oapply_typed(type_system::PropertyLabelledPetriNet, uwd, tnames::Vector{Symbol})
  oapply_typed(LabelledPetriNet(type_system), uwd, tnames)
end

