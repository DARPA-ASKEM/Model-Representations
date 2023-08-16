module SyntacticModelsBase

using StructTypes
using JSON3
import Base: Dict

export AbstractTerm, _dict, typename_last

abstract type AbstractTerm end
# we are going to convert our structs to Dict before we call JSON3.write and 
# add the type information in a generic construction. This uses some reflection 
# to ask the julia type for its fieldnames and then use those as the keys in the Dict.
# we use splatting, so don't make a struct with more than 32 fields if you want to go fast.
# we use this _dict function to avoid an "I'm the captain now" level of type piracy.
typename_last(T::Type) = T.name.name

_dict(x::Symbol) = x
_dict(x::String) = x
_dict(x::Number) = x
_dict(x::AbstractVector) = map(_dict, x)
function _dict(x::T) where {T<:AbstractTerm}
  Dict(:_type => typename_last(T), [k=>_dict(getfield(x, k)) for k in fieldnames(T)]...)
end

# to register your type with JSON3, you need to overload JSON3.write to use this Dict approach.
# we only overload the Dict function for our type Formula, so this is not piracy.
Dict(x::AbstractTerm) = _dict(x)

# Now JSON3.write(Dict(f)) puts the type information in our reserved field.
JSON3.write(f::AbstractTerm) = JSON3.write(Dict(f))

StructTypes.StructType(::Type{AbstractTerm}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractTerm}) = :_type
end