module SerializationTest
using MLStyle
using JSON3
using Test

# Our Formula type is a recursive ADT definition the terminal types are Values and Variables,
# The mathematical operator goes in the type of the struct. This is unlike Julia Expr types,
# where the operator is a symbol in the first argument position of the expression tree.
@data Formula begin
  Val(x::Number)
  Var(s::Symbol)
  Plus(a::Formula, b::Formula)
  Times(a::Formula, b::Formula)
end

f = Times(Plus(Var(:x), Val(3.2)), Plus(Var(:y), Val(5.4)))

# Note: there is no type information in the output, 
# therefore we won't be able to read it back in
s = JSON3.write(f)
println(s)

# we could convert the formula to a dict with structural recursion
# and manually add in the type information on every step of the recursion
function dict(f::Formula)
  let ! = dict 
    @match f begin
      Times(a,b) => Dict(:head=>:Times, :left=>!a, :right=>!b)
      Plus(a,b)  => Dict(:head=>:Plus, :left=>!a, :right=>!b)
      Var(a)  => Dict(:head=>:Var, :name=>a)
      Val(a)  => Dict(:head=>:Val, :value=>string(a))
    end
  end
end

# Now JSON3.write works.
s′ =(dict(f) |> JSON3.write)

s′|> println

# But then we have to write our deserializer by hand.
function load(::Type{Formula}, d::JSON3.Object)
  t = d.head
  let ! = x -> load(Formula, x)
    @match t begin
      "Times" => Times(!d.left, !d.right)
      "Plus" => Plus(!d.left, !d.right)
      "Var" => Var(Symbol(d.name))
      "Val" => Val(parse(Float64, d.value))
      _ => error("Got a $(typeof(d)), $t, $d)")
    end
  end
end

# this works, but was manual.
d = JSON3.read(s′)
load(Formula, d)

# StructTypes provides a traits-based interface to avoid that manual construction
using StructTypes

# this code is tweaked from the AbstractType example in the StructTypes docs.
StructTypes.StructType(::Type{Formula}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{Formula}) = :_type
StructTypes.subtypes(::Type{Formula}) = (Plus=Plus, Times=Times, Var=Var, Val=Val)

# Sadly, that doesn't make JSON3.write "just work". This seems like a bug in StructTypes or JSON3.
StructTypes.constructfrom(AbstractDict, f)
JSON3.write(f) |> println

# It did make JSON3.read "just work" as long as we get the serializer to put the type fields in the output.

JSON3.read("""
  {"_type":"Plus",
    "a": {"x":3, "_type":"Val"},
    "b": {"s":"x", "_type":"Var"}
  }
""", Formula)

# we are going to convert our structs to Dict before we call JSON3.write and 
# add the type information in a generic construction. This uses some reflection 
# to ask the julia type for its fieldnames and then use those as the keys in the Dict.
# we use splatting, so don't make a struct with more than 32 fields if you want to go fast.
import Base: Dict

# we use this _dict function to avoid an "I'm the captain now" level of type piracy.
_dict(x) = x
function _dict(x::T) where {T<:Formula}
  Dict(:_type => T.name.name, [k=>_dict(getfield(x, k)) for k in fieldnames(T)]...)
end
# we only overload the Dict function for our type Formula, so this is not piracy.
Dict(x::Formula) = _dict(x)

# Now JSON3.write(Dict(f)) puts the type information in our reserved field.
Dict(f)
JSON3.write(Dict(f)) |> println

# JSON3.read has the information it needs to identify the types.
f′ = JSON3.read(JSON3.write(Dict(f)), Formula)
@test f′ == f
end