module ASKEMPetriNets

export AbstractASKEMPetriNet, ASKEMPetriNet, TypedASKEMPetriNet, StratifiedASKEMPetriNet, model, typed_model, update!

using AlgebraicPetri
using AlgebraicPetri: PropertyLabelledPetriNetUntyped
using Catlab
using Catlab.CategoricalAlgebra.CSets: ACSetLimit

import JSON

const StringDict = Dict{String,Any}
const JSONPetri = PropertyLabelledPetriNet{StringDict}

abstract type AbstractASKEMPetriNet end

struct ASKEMPetriNet <: AbstractASKEMPetriNet
  model::AbstractPetriNet
  json::AbstractDict
end

struct TypedASKEMPetriNet <: AbstractASKEMPetriNet
  model::ACSetTransformation
  json::AbstractDict
end

struct StratifiedASKEMPetriNet <: AbstractASKEMPetriNet
  model::ACSetLimit
  json::AbstractDict
end

model(askem_net::ASKEMPetriNet) = askem_net.model
model(askem_net::TypedASKEMPetriNet) = dom(askem_net.model)
model(askem_net::StratifiedASKEMPetriNet) = apex(askem_net.model)
typed_model(askem_net::TypedASKEMPetriNet) = askem_net.model
typed_model(askem_net::StratifiedASKEMPetriNet) = first(legs(askem_net.model.cone)) ⋅ first(legs(askem_net.model.diagram))

flat_symbol(sym::Symbol; sep="_")::Symbol = sym
flat_symbol(sym::Tuple; sep="_")::Symbol = mapreduce(x -> isa(x, Tuple) ? flat_symbol(x, sep) : x, (x, y) -> Symbol(x, sep, y), sym)
flat_string(args...) = String(flat_symbol(args...))
           
#**********************************************************
# Functions to extract Petri net structures from AMR JSON *
#**********************************************************

function extract_petri(model::AbstractDict)
  state_props = Dict(Symbol(s["id"]) => s for s in model["states"])
  states = [Symbol(s["id"]) for s in model["states"]]
  transition_props = Dict(Symbol(t["id"]) => t for t in model["transitions"])
  transitions = [Symbol(t["id"]) => (Symbol.(t["input"]) => Symbol.(t["output"])) for t in model["transitions"]]

  JSONPetri(LabelledPetriNet(states, transitions...), state_props, transition_props)
end

function extract_typing(dom::PropertyLabelledPetriNet,typing_dict::AbstractDict)
  type_system = extract_petri(typing_dict["system"]["model"])
  type_map = Dict(Symbol(k)=>Symbol(v) for (k,v) in typing_dict["map"])
  S = map(snames(dom)) do state
    only(incident(type_system, type_map[state], :sname))
  end
  T = map(tnames(dom)) do transition
    only(incident(type_system, type_map[transition], :tname))
  end
  type_its = Dict{Int,Vector{Int}}()
  I = map(parts(dom, :I)) do i
    type_transition = T[dom[i, :it]]
    if !haskey(type_its, type_transition) || isempty(type_its[type_transition])
      type_its[type_transition] = copy(incident(type_system, type_transition, :it))
    end
    popfirst!(type_its[type_transition])
  end
  type_ots = Dict{Int,Vector{Int}}()
  O = map(parts(dom, :O)) do o
    type_transition = T[dom[o, :ot]]
    if !haskey(type_ots, type_transition) || isempty(type_ots[type_transition])
      type_ots[type_transition] = copy(incident(type_system, type_transition, :ot))
    end
    popfirst!(type_ots[type_transition])
  end
  LooseACSetTransformation((S=S, T=T, I=I, O=O), (Name=x->nothing, Prop=x->nothing), dom, type_system)
end

function extract_span(apex::PropertyLabelledPetriNet,span_dict::Vector{Any}) # Dict{String,Any}})
  span = Vector{ACSetTransformation}()
  for leg in span_dict
    push!(span,extract_typing(apex,leg))
  end
  return span
end

#**************************************************************************
# Constructors for AbstractASKEMPetriNets from file or base ASKEMPetriNet *
#**************************************************************************

ASKEMPetriNet(json::AbstractDict) = ASKEMPetriNet(extract_petri(json["model"]), json)

ASKEMPetriNet(file::AbstractString) = ASKEMPetriNet(JSON.parsefile(file))

ASKEMPetriNet(typed_petri::TypedASKEMPetriNet) = ASKEMPetriNet(typed_petri.model.dom, typed_petri.json)

ASKEMPetriNet(strat_petri::StratifiedASKEMPetriNet) = ASKEMPetriNet(apex(strat_petri.model), strat_petri.json)

TypedASKEMPetriNet(petri::ASKEMPetriNet) = begin
  dom = petri.model
  typing = petri.json["semantics"]["typing"]
  tpn = extract_typing(dom,typing)
  TypedASKEMPetriNet(tpn, petri.json)
end

TypedASKEMPetriNet(json::AbstractDict) = begin
  dom = extract_petri(json["model"])
  typing = json["semantics"]["typing"]
  tpn = extract_typing(dom, typing)
  TypedASKEMPetriNet(tpn, json)
end

TypedASKEMPetriNet(file::AbstractString) = TypedASKEMPetriNet(JSON.parsefile(file))

#=
StratifiedASKEMPetriNet(petri::ASKEMPetriNet) = begin
  spn = petri.json["semantics"]["span"]
  lgs = [TypedASKEMPetriNet(lg["system"]).model for lg in spn]
  StratifiedASKEMPetriNet(pullback(lgs; product_attrs=true), petri.json)
end
=#

StratifiedASKEMPetriNet(json::AbstractDict) = begin
  spn = json["semantics"]["span"]
  lgs = [TypedASKEMPetriNet(lg["system"]).model for lg in spn]
  StratifiedASKEMPetriNet(pullback(lgs; product_attrs=true), json)
end

StratifiedASKEMPetriNet(file::AbstractString) = StratifiedASKEMPetriNet(JSON.parsefile(file))

function StratifiedASKEMPetriNet(pb::ACSetLimit, ps::AbstractVector{TypedASKEMPetriNet})
  pn = apex(pb)
  json = StringDict(
    "name"=>"",
    "description"=>"",
    "model_version"=>"0.1",
    "schema"=>"https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/petrinet_v0.5/petrinet/petrinet_schema.json"
  )
  json["model"] = StringDict(
    "states"=>map(parts(pn, :S)) do s
      StringDict("id"=>flat_string(pn[s, :sname]))
    end,
    "transitions"=>map(parts(pn, :T)) do t
      StringDict(
        "id"=>flat_string(pn[t, :tname]),
        "input"=>flat_string.(pn[pn[incident(pn, t, :it), :is], :sname]),
        "output"=>flat_string.(pn[pn[incident(pn, t, :ot), :os], :sname]),
      )
    end
  )
  json["semantics"] = StringDict()
  json["semantics"]["typing"] = StringDict(
    "system"=>first(ps).json["semantics"]["typing"]["system"],
    "map"=>type_map(first(legs(pb.cone)) ⋅ first(legs(pb.diagram)))
  )
  json["semantics"]["span"] = map(enumerate(legs(pb))) do (i, leg)
    json["name"] *= string(json["name"] == "" ? "" : " + ", ps[i].json["name"])
    json["description"] *= string(json["description"] == "" ? "" : " ; ", ps[i].json["description"])
    return StringDict("system"=>ps[i].json, "map"=>type_map(leg))
  end
  StratifiedASKEMPetriNet(pb, json)
end

StratifiedASKEMPetriNet(p1::TypedASKEMPetriNet, p2::TypedASKEMPetriNet) = StratifiedASKEMPetriNet(pullback(p1.model, p2.model; product_attrs=true), [p1, p2])
StratifiedASKEMPetriNet(ps::AbstractVector{TypedASKEMPetriNet}) = StratifiedASKEMPetriNet(pullback(ps; product_attrs=true), ps)

#**********************************************************************
# Functions to form AMR semantic components of AbstractASKEMPetriNets *
#**********************************************************************

function type_map(typed_petri::ACSetTransformation)
  comps, pn, type_system = typed_petri.components, typed_petri.dom, typed_petri.codom
  vcat(
    map(enumerate(force(comps.S).func)) do (state, type)
      [flat_string(pn[state, :sname]), flat_string(type_system[type, :sname])]
    end,
    map(enumerate(force(comps.T).func)) do (transition, type)
      [flat_string(pn[transition, :tname]), flat_string(type_system[type, :tname])]
    end
  )
end

function form_typing_semantics(tpn::ACSetTransformation)
  semantics = StringDict()
  semantics["system"] = form_amr(codom(tpn))
  semantics["map"] = type_map(tpn)
  return semantics
end

function form_span_semantics(span::Vector{ACSetTransformation})
  semantics = Vector{StringDict}()
  for leg in span
    push!(semantics,form_typing_semantics(leg))
  end
  return semantics
end

#*************************************************************
# Functions to form AMR dictionary of AbstractASKEMPetriNets *
#*************************************************************

# function form_amr(pn::PropertyLabelledPetriNet; 
function form_amr(pn::AbstractPetriNet; 
    name="A Petri Net", 
  schema="https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/petrinet_v0.5/petrinet/petrinet_schema.json", 
  description="A Petri net in AMR format",
  version="0.1",
  semantics=StringDict(),
  meta=StringDict())

  amr = StringDict()
  amr["name"] = name
  amr["schema"] = schema
  amr["description"] = description
  amr["model_version"] = version
  amr["semantics"] = semantics
  amr["metadata"] = meta

  amr["model"] = StringDict(
    "states"=>map(parts(pn, :S)) do s
      StringDict("id"=>flat_string(pn[s, :sname]))
    end,
    "transitions"=>map(parts(pn, :T)) do t
      StringDict(
        "id"=>flat_string(pn[t, :tname]),
        "input"=>flat_string.(pn[pn[incident(pn, t, :it), :is], :sname]),
        "output"=>flat_string.(pn[pn[incident(pn, t, :ot), :os], :sname]),
      )
    end
  )
  return amr
end

function form_amr(tpn::ACSetTransformation)
  amr = form_amr(dom(tpn),name="A Typed Petri Net", description="A typed Petri net in AMR format")
  amr["semantics"] = StringDict()
  amr["semantics"]["typing"] = form_typing_semantics(tpn)
  return amr
end

function form_amr(pb::ACSetLimit)
  amr = form_amr(pn,name="A Stratified Petri Net", description="A stratified Petri net in AMR format")  
  amr["semantics"] = StringDict()
  amr["semantics"]["typing"] = form_typing_semantics(first(legs(pb.cone)) ⋅ first(legs(pb.diagram)))
  amr["semantics"]["span"] = form_span_semantics(legs(pb.diagram))
  return amr
end

#********************************************
# Functions to update AbstractASKEMPetriNet *
#********************************************

function update!(pn::PropertyLabelledPetriNet)
  map(parts(pn, :S)) do s
    pn[s, :sprop]["id"] = String(pn[s, :sname])
  end
  map(parts(pn, :T)) do t
    props = pn[t, :tprop]
    props["id"] = String(pn[t, :tname])
    new_inputs = String.(pn[pn[incident(pn, t, :it), :is], :sname])
    for (i, input) in enumerate(props["input"])
      props["input"][i] = new_inputs[i]
    end
    new_outputs = String.(pn[pn[incident(pn, t, :ot), :os], :sname])
    for (o, output) in enumerate(props["output"])
      props["output"][o] = new_outputs[o]
    end
  end
  pn
end

function update!(askem_net::ASKEMPetriNet)
  update!(askem_net.model)
  askem_net
end

function update!(askem_net::TypedASKEMPetriNet)
  update!(askem_net.model.dom)
  update!(askem_net.model.codom)
  askem_net.json["semantics"]["typing"]["map"] = type_map(askem_net.model)
  askem_net
end

function update!(askem_net::StratifiedASKEMPetriNet)
  # TODO: Update! for models with tuples of attributes
  # update!(TypedASKEMPetriNet(typed_model(askem_net), askem_net.json))
  span_legs = legs(askem_net.model)
  map(enumerate(legs(askem_net.model.diagram))) do (i, leg)
    leg_json = askem_net.json["semantics"]["span"][i]
    update!(TypedASKEMPetriNet(leg, leg_json["system"]))
    leg_json["map"] = type_map(span_legs[i])
  end
  askem_net
end

# JSON Interoperability
#######################

JSON.json(askem_net::AbstractASKEMPetriNet) = JSON.json(askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet) = JSON.print(io, askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet, indent) = JSON.print(io, askem_net.json, indent)

end
