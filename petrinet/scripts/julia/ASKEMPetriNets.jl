module ASKEMPetriNets

export to_petri, to_typed_petri, update_properties!, update_json!, update!

using AlgebraicPetri
using Catlab.CategoricalAlgebra

import JSON

abstract type AbstractASKEMPetriNet end

struct ASKEMPetriNet <: AbstractASKEMPetriNet
  model::PropertyLabelledPetriNet
  json::AbstractDict
end

struct TypedASKEMPetriNet <: AbstractASKEMPetriNet
  model::ACSetTransformation
  json::AbstractDict
end

function extract_petri(model::AbstractDict)
  state_props = Dict(Symbol(s["id"]) => s for s in model["states"])
  states = [Symbol(s["id"]) for s in model["states"]]
  transition_props = Dict(Symbol(t["id"]) => t for t in model["transitions"])
  transitions = [Symbol(t["id"]) => (Symbol.(t["input"]) => Symbol.(t["output"])) for t in model["transitions"]]

  PropertyLabelledPetriNet{Dict}(LabelledPetriNet(states, transitions...), state_props, transition_props)
end

function to_petri(file::AbstractString)
  json = JSON.parsefile(file)
  ASKEMPetriNet(extract_petri(json["model"]), json)
end

to_petri(typed_petri::TypedASKEMPetriNet) = ASKEMPetriNet(typed_petri.model.dom, typed_petri.json)

function to_typed_petri(petri::ASKEMPetriNet)
  typing = petri.json["semantics"]["typing"]
  type_system = extract_petri(typing["type_system"])
  type_map = Dict(Symbol(k)=>Symbol(v) for (k,v) in typing["type_map"])
  S = map(snames(petri.model)) do state
    only(incident(type_system, type_map[state], :sname))
  end
  T = map(tnames(petri.model)) do transition
    only(incident(type_system, type_map[transition], :tname))
  end
  type_its = Dict{Int,Vector{Int}}()
  I = map(parts(petri.model, :I)) do i
    type_transition = T[petri.model[i, :it]]
    if !haskey(type_its, type_transition) || isempty(type_its[type_transition])
      type_its[type_transition] = copy(incident(type_system, type_transition, :it))
    end
    popfirst!(type_its[type_transition])
  end
  type_ots = Dict{Int,Vector{Int}}()
  O = map(parts(petri.model, :O)) do o
    type_transition = T[petri.model[o, :ot]]
    if !haskey(type_ots, type_transition) || isempty(type_ots[type_transition])
      type_ots[type_transition] = copy(incident(type_system, type_transition, :ot))
    end
    popfirst!(type_ots[type_transition])
  end

  TypedASKEMPetriNet(LooseACSetTransformation((S=S, T=T, I=I, O=O), (Name=x->nothing, Prop=x->nothing), petri.model, type_system), petri.json)
end

to_typed_petri(file::AbstractString) = to_typed_petri(to_petri(file))

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

update!(askem_net::TypedASKEMPetriNet) = begin
  update!(askem_net.model.dom)
  update!(askem_net.model.codom)
  comps, pn, type_system = askem_net.model.components, askem_net.model.dom, askem_net.model.codom
  askem_net.json["semantics"]["typing"]["type_map"] = vcat(
    map(enumerate(comps.S.func)) do (state, type)
      [String(pn[state, :sname]), String(type_system[type, :sname])]
    end,
    map(enumerate(comps.T.func)) do (transition, type)
      [String(pn[transition, :tname]), String(type_system[type, :tname])]
    end
  )
  askem_net
end

# JSON Interoperability
#######################

JSON.json(askem_net::AbstractASKEMPetriNet) = JSON.json(askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet) = JSON.print(io, askem_net.json)
JSON.print(io::IO, askem_net::AbstractASKEMPetriNet, indent) = JSON.print(io, askem_net.json, indent)

end
