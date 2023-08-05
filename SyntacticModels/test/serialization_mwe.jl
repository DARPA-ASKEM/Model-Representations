using MLStyle

@data Formula begin
  Val(x::Number)
  Var(s::Symbol)
  Plus(a::Formula, b::Formula)
  Times(a::Formula, b::Formula)
end

f = Times(Plus(Var(:x), Val(3)), Plus(Var(:y), Val(5)))

using JSON3

s = JSON3.write(f)
println(s)

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

s′ =(dict(f) |> JSON3.write)

s′|> println


function load(::Type{Formula}, d::JSON3.Object)
  t = d.head
  let ! = x -> load(Formula, x)
    @match t begin
      "Times" => Times(!d.left, !d.right)
      "Plus" => Plus(!d.left, !d.right)
      "Var" => Var(Symbol(d.name))
      "Val" => Val(parse(Int, d.value))
      _ => error("Got a $(typeof(d)), $t, $d)")
    end
  end
end

d = JSON3.read(s′)
load(Formula, d)