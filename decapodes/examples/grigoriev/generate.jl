using Decapodes, CombinatorialSpaces, GeometryBasics, FileIO, SyntacticModels, Catlab

# Specify these paths:
#include("~/Decapodes.jl/examples/grid_meshes.jl")

# Generate and save the primal and dual meshes:
const MIN_X = 4648894.5
const MAX_X = 4652179.7
const MIN_Y = 243504.5
const MAX_Y = 245599.8
RES_Y = (MAX_Y-MIN_Y)/30.0
RES_X = RES_Y
s′ = triangulated_grid(
                       MAX_X-MIN_X, MAX_Y-MIN_Y,
                       RES_X, RES_Y, Point3D)
s′[:point] = map(x -> x + Point3D(MIN_X, MIN_Y, 0), s′[:point])
s = EmbeddedDeltaDualComplex2D{Bool, Float64, Point3D}(s′)
subdivide_duals!(s, Barycenter())

save("primal_mesh.obj", GeometryBasics.Mesh(s′))
save("dual_mesh.obj", GeometryBasics.Mesh(s))

# Generate and save the model:
halfar_eq2 = @decapode begin
  h::Form0
  Γ::Form1
  n::Constant

  ḣ == ∂ₜ(h)
  ḣ == ∘(⋆, d, ⋆)(Γ * d(h) * avg₀₁(mag(♯(d(h)))^(n-1)) * avg₀₁(h^(n+2)))
end

glens_law = @decapode begin
  Γ::Form1
  (A,ρ,g,n)::Constant
  
  Γ == (2/(n+2))*A*(ρ*g)^n
end

ice_dynamics_composition_diagram = @relation () begin
  dynamics(h,Γ,n)
  stress(Γ,n)
end

ice_dynamics_cospan = oapply(ice_dynamics_composition_diagram,
  [Open(halfar_eq2, [:h,:Γ,:n]),
  Open(glens_law, [:Γ,:n])])

ice_dynamics = apex(ice_dynamics_cospan)

SyntacticModels.ASKEMDecapodes.ASKEMDecapode(
  SyntacticModels.AMR.Header("Halfar ice dynamics",
         "https://raw.githubusercontent.com/DARPA-ASKEM/Model-Representations/main/decapodes/json/model_schema.json",
         "Halfar ice dynamics",
         "decapodes",
         "0.1"),
  ice_dynamics)

