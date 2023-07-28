using ..SyntacticModels
using ..SyntacticModels.ASKEMUWDs

using JSON
using Catlab.RelationalPrograms
using Catlab.WiringDiagrams
using Catlab.Graphics

# This example follows what in current catlab would be given as

#=
@relation (x:X, z:Z) where y:Y begin
  R(x,y)
  S(y,z)
  T(z,y,u)
end
=#

v1 = Typed(:x, :X)
v2 = Typed(:y, :Y)
v3 = Typed(:z, :Z)
v4 = Untyped(:u)
c = [v1, v3]
s = [Statement(:R, [v1,v2]),
  Statement(:S, [v2,v3]),
  Statement(:T, [v3,v2, v4])]
u = UWDExpr(c, s)
uwd = ASKEMUWDs.construct(RelationDiagram, u)


println(u)
JSON.print(u, 2)

to_graphviz(uwd, box_labels=:name, junction_labels=:variable)

display(uwd)