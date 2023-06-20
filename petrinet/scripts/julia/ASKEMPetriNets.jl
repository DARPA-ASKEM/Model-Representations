module ASKEMPetriNets

export ASKEMPetriNet, TypedASKEMPetriNet, update_properties!, update_json!, update!, SpanASKEMPetriNet, StratifiedASKEMPetriNet

using AlgebraicPetri
using Catlab.CategoricalAlgebra

import Catlab.CategoricalAlgebra.CSets: ACSetLimit

import JSON

abstract type AbstractASKEMPetriNet end

struct ASKEMPetriNet <: AbstractASKEMPetriNet
  model::PropertyLabelledPetriNet
  json::AbstractDict
end

struct TypedASKEMPetriNet <: AbstractASKEMPetriNet
  model::PropertyLabelledPetriNet
  typing::ACSetTransformation
  json::AbstractDict
end

struct SpanASKEMPetriNet <: AbstractASKEMPetriNet
  model::PropertyLabelledPetriNet
  legs::Vector{ACSetTransformation}
  json::AbstractDict
end

struct StratifiedASKEMPetriNet <: AbstractASKEMPetriNet
  model::PropertyLabelledPetriNet # apex
  typing::ACSetTransformation
  legs::Vector{ACSetTransformation}
  json::AbstractDict
end


#**********************************************************
# Functions to extract Petri net structures from AMR JSON *
#**********************************************************
function extract_petri(model::AbstractDict)
  state_props = Dict(Symbol(s["id"]) => s for s in model["states"])
  states = [Symbol(s["id"]) for s in model["states"]]
  transition_props = Dict(Symbol(t["id"]) => t for t in model["transitions"])
  transitions = [Symbol(t["id"]) => (Symbol.(t["input"]) => Symbol.(t["output"])) for t in model["transitions"]]

  PropertyLabelledPetriNet{Dict}(LabelledPetriNet(states, transitions...), state_props, transition_props)
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

#***************************************************************************
# Constructors for AbstractASKEMPetriNet's from file or base ASKEMPetriNet *
#***************************************************************************
ASKEMPetriNet(file::AbstractString) = begin
  json = JSON.parsefile(file)
  ASKEMPetriNet(extract_petri(json["model"]), json)
end

# ASKEMPetriNet(typed_petri::TypedASKEMPetriNet) = ASKEMPetriNet(typed_petri.model.dom, typed_petri.json)
# ASKEMPetriNet(span_petri::SpanASKEMPetriNet) = ASKEMPetriNet(span_petri.model[1].dom, span_petri.json)

TypedASKEMPetriNet(petri::ASKEMPetriNet) = begin
  dom = petri.model
  typing = petri.json["semantics"]["typing"]
  tpn = extract_typing(dom,typing)
  TypedASKEMPetriNet(dom, tpn, petri.json)
end
TypedASKEMPetriNet(file::AbstractString) = TypedASKEMPetriNet(ASKEMPetriNet(file))

SpanASKEMPetriNet(petri::ASKEMPetriNet) = begin
  apex = petri.model
  feet = petri.json["semantics"]["span"]
  legs = extract_span(apex,feet)
  SpanASKEMPetriNet(apex, legs, petri.json)
end
SpanASKEMPetriNet(file::AbstractString) = SpanASKEMPetriNet(ASKEMPetriNet(file))

StratifiedASKEMPetriNet(tmp::ASKEMPetriNet) = begin
  apex = tmp.model
  typing = extract_typing(apex,tmp.json["semantics"]["stratification"]["typing"])
  legs = extract_span(apex,tmp.json["semantics"]["stratification"]["span"])
  StratifiedASKEMPetriNet(apex,typing,legs,tmp.json)
end
StratifiedASKEMPetriNet(file::AbstractString) = begin
  tmp = ASKEMPetriNet(file)
  StratifiedASKEMPetriNet(tmp)
end

#***************************************************************
# Functions to form AMR semantic components of data structures *
#***************************************************************
function form_map_semantics(tpn::ACSetTransformation)
  map_pairs = []
  for (ii,s) in enumerate(dom(tpn)[:sname])
    push!(map_pairs,[String(s),String(codom(tpn)[:sname][components(tpn)[:S](ii)])])
  end
  for (ii,t) in enumerate(dom(tpn)[:tname])
    push!(map_pairs,[String(t),String(codom(tpn)[:tname][components(tpn)[:T](ii)])])
  end
  return map_pairs
end

function form_typing_semantics(tpn::ACSetTransformation)
  semantics = Dict{String,Any}()
  semantics["system"] = form_amr(codom(tpn))
  semantics["map"] = form_map_semantics(tpn)
  return semantics
end

function form_span_semantics(span::Vector{ACSetTransformation})
  semantics = Vector{Dict{String,Any}}()
  for leg in span
    push!(semantics,form_typing_semantics(leg))
  end
  return semantics
end

#******************************************************
# Functions to form AMR dictionary of data structures *
#******************************************************

#=function form_amr(lpn::AbstractLabelledPetriNet)
  ppn = PropertyLabelledPetriNet{Dict}()
  copy_parts!(ppn,flatten_labels(lpn))
  update!(ppn)
  @show ppn
  form_amr(ppn)
end
=#

function form_amr(pn::PropertyLabelledPetriNet; 
                name="A Petri Net", 
                schema="https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/petrinet_v0.5/petrinet/petrinet_schema.json", 
                description="A Petri net in AMR format",
                version="0.1",
                semantics=Dict{String,Any}(),
                meta=Dict{String,Any}())

  # pn_schema = JSON.parsefile("../../petrinet_schema.json")
  amr = Dict{String,Any}()
  #=
  for field in filter(x -> x != "model", pn_schema["required"])
    amr[field] = ""
  end
  =#
  amr["name"] = name
  amr["schema"] = schema
  amr["description"] = description
  amr["model_version"] = version
  amr["semantics"] = semantics
  amr["metadata"] = meta
  
  amr["model"] = Dict{String,Any}()
  amr["model"]["states"] = pn[:sprop]
  amr["model"]["transitions"] = pn[:tprop]
  return amr
end

function form_amr(tpn::ACSetTransformation)
  amr = form_amr(dom(tpn),name="A Typed Petri Net", description="A typed Petri net in AMR format")
  amr["semantics"] = Dict{String,Any}()
  amr["semantics"]["typing"] = form_typing_semantics(tpn)
  return amr
end

function form_amr(spn::Vector{ACSetTransformation})
  amr = form_amr(dom(spn[1]),name="A Span of Petri Nets", description="A span of Petri nets in AMR format")
  amr["semantics"] = Dict{String,Any}()
  amr["semantics"]["span"] = form_span_semantics(spn)
  return amr
end

function form_amr(pn::PropertyLabelledPetriNet,tpn::ACSetTransformation,span::Vector{ACSetTransformation})
  amr = form_amr(pn,name="A Stratified Petri Net", description="A stratified Petri net in AMR format")
  amr["semantics"] = Dict{String,Any}()
  amr["semantics"]["stratification"] = Dict{String,Any}()
  amr["semantics"]["stratification"]["typing"] = form_typing_semantics(tpn)
  amr["semantics"]["stratification"]["span"] = form_span_semantics(span)
  return amr
end

#**************************************************************************************
# Functions to convert Petri net structures between forms with and without properties *
#**************************************************************************************
function tppn_to_tlpn(tppn::ACSetTransformation)
  dom_petri = LabelledPetriNet(deepcopy(dom(tppn)))
  codom_petri = LabelledPetriNet(deepcopy(codom(tppn)))
  type_comps = Dict(k=>collect(v) for (k,v) in pairs(deepcopy(components(tppn))))
  delete!(type_comps,:Prop)
  LooseACSetTransformation(
    type_comps,
    # (Name=x->nothing),
    (Name=x->nothing, (has_subpart(dom_petri, :rate) ? [:Rate=>x->nothing] : [])..., (has_subpart(dom_petri, :concentration) ? [:Concentration=>x->nothing] : [])...),
    dom_petri,
    codom_petri
  )
end

#**NOTE** This function may need correcting to align with extract_petri s.t. it roundtrips
function lpn_to_ppn(lpn::AbstractLabelledPetriNet)
  ppn = PropertyLabelledPetriNet{Dict}()
  copy_parts!(ppn, flatten_labels(lpn))
  ppn[:sprop] = [Dict{String,Any}() for i in parts(ppn, :S)]
  ppn[:tprop] = [Dict{String,Any}("input"=>[], "output"=>[]) for i in parts(ppn, :T)]
  for t in parts(ppn, :T)
    ppn[t, :tprop]["id"] = string(ppn[t, :tname])
    ppn[t, :tprop]["input"] = string.(ppn[i,[:is, :sname]] for i in incident(ppn, t, :it))
    ppn[t, :tprop]["output"] = string.(ppn[o,[:os, :sname]] for o in incident(ppn, t, :ot))
  end
  for s in parts(ppn, :S)
    ppn[s, :sprop]["id"] = string(ppn[s, :sname])
  end
  # ASKEMPetriNet(ppn, Dict())
  ppn
end

function tlpn_to_tppn(tlpn::ACSetTransformation)
  dom_petri = lpn_to_ppn(deepcopy(dom(tlpn)))
  codom_petri = lpn_to_ppn(deepcopy(codom(tlpn)))
  type_comps = Dict(k=>collect(v) for (k,v) in pairs(deepcopy(components(tlpn))))
  LooseACSetTransformation(
    type_comps,
    # (Name=x->nothing),
    (Name=x->nothing, (has_subpart(dom_petri, :rate) ? [:Rate=>x->nothing] : [])..., (has_subpart(dom_petri, :concentration) ? [:Concentration=>x->nothing] : [])...),
    dom_petri,
    codom_petri
  )
end

#=
#********************************************************
# Initial attempts at functions for a nested AMR format *
#********************************************************

struct NestedASKEMPetriNet <: AbstractASKEMPetriNet
  model::Union{ASKEMPetriNet,TypedASKEMPetriNet,SpanASKEMPetriNet}
  semantics::AbstractDict
  json::AbstractDict
end

function to_nested_petri(petri::AbstractASKEMPetriNet)
end

function to_nested_petri(json::AbstractDict)
  mdl = extract_petri(json["model"])
  if maps in petri.json["semantics"]
    for map in maps
      codom = to_nested_petri(map)
      form acsettransformation
    end
  else

  end
  
  ASKEMPetriNet(, json)
end

function to_nested_petri(file::AbstractString)
  json = JSON.parsefile(file)
  to_nested_petri(json)
end
=#


#=
#*******************************************************************
# Initial sketch from James of an MLStyle setup for AMR formatting *
#*******************************************************************

struct AMR{T}
  name::String
  schema::URL
  schema_name::String
  model::T
  semantics::Semantics
end

struct Semantics
  v::Vector{AbstractSemantic}
end

abstract type AbstractSemantic end

struct ODESemantic <: AbstractSemantic
  rates::Vector{}
end

struct Semantic{T}
  name::String
  payload::T
end

function AMR{PropertyLabelledPetriNet}(payload::AbstractDict)
  AMR(
    payload["name"]
    payload["schema"]
    payload["schema_name"]
    extract_petri(payload["model"])
    extract_semantics(payload["semantics"])
  )

  extract_semantics(payload::AbstractDict) = begin
    for k in keys(payload)
      if key == ode
        Semantic{:ODE}
    end
  end
=#

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

function update!(typing::ACSetTransformation,typ_dict::AbstractDict)
  update!(typing.dom)
  update!(typing.codom)
  comps, pn, type_system = typing.components, typing.dom, typing.codom
  typ_dict["map"] = vcat(
    map(enumerate(comps.S.func)) do (state, type)
      [String(pn[state, :sname]), String(type_system[type, :sname])]
    end,
    map(enumerate(comps.T.func)) do (transition, type)
      [String(pn[transition, :tname]), String(type_system[type, :tname])]
    end
  )
end

function update!(askem_net::TypedASKEMPetriNet)
  update!(askem_net.model)
  update!(askem_net.typing,askem_net.json["semantics"]["typing"])
#=
  update!(askem_net.typing.dom)
  update!(askem_net.typing.codom)
  comps, pn, type_system = askem_net.typing.components, askem_net.typing.dom, askem_net.typing.codom
  askem_net.json["semantics"]["typing"]["map"] = vcat(
    map(enumerate(comps.S.func)) do (state, type)
      [String(pn[state, :sname]), String(type_system[type, :sname])]
    end,
    map(enumerate(comps.T.func)) do (transition, type)
      [String(pn[transition, :tname]), String(type_system[type, :tname])]
    end
  )
=#
  askem_net
end

function update!(askem_net::SpanASKEMPetriNet)
  update!(askem_net.model)
  for (ii, leg) in enumerate(askem_net.legs)
    update!(leg,askem_net.json["semantics"]["span"][ii])
#=
    update!(leg.dom)
    update!(leg.codom)
    comps, pn, type_system = leg.components, leg.dom, leg.codom
    askem_net.json["semantics"]["span"][ii]["map"] = vcat(
      map(enumerate(comps.S.func)) do (state, type)
        [String(pn[state, :sname]), String(type_system[type, :sname])]
      end,
      map(enumerate(comps.T.func)) do (transition, type)
        [String(pn[transition, :tname]), String(type_system[type, :tname])]
      end
    )
=#
  end
  askem_net
end

function update!(askem_net::StratifiedASKEMPetriNet)
  update!(askem_net.model)
  update!(askem_net.typing,askem_net.json["semantics"]["typing"])
  for (ii, leg) in enumerate(askem_net.legs)
    update!(leg,askem_net.json["semantics"]["span"][ii])
  end
  askem_net
end

#************************
# JSON Interoperability *
#************************
JSON.json(askem_net::AbstractASKEMPetriNet) = JSON.json(askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet) = JSON.print(io, askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet, indent) = JSON.print(io, askem_net.json, indent)

end
