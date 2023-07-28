"""
ASKE Model Representation: SIR@v0.2 :: petrinet 
   amr-schemas:petri_schema.json

The SIR Model of disease
"""
Model = begin
  LabelledPetriNet{Symbol} begin 
    S(label=:S)
    S(label=:I)
    S(label=:R)
    T(label=:inf)
    T(label=:rec)
    I(is=:S,it=:inf)
    I(is=:I,it=:inf)
    I(is=:I,it=:rec)
    O(os=:I,it=:inf)
    O(os=:I,it=:inf)
    O(os=:R,it=:rec)
   end
end

ODE Equations: begin
  t::Time{day}
  
  
  # β -- the beta parameter
  β::Parameter{1/(persons^2*day)} = 0.01 ~ U(0.001,0.02)
  
  inf::Rate = S*I*β
  
  # γ -- the gama parameter
  γ::Parameter{1/(persons*day)} = 3.0 ~ U(1,200.0)
  
  rec::Rate = I*γ
  
  # S₀ -- the initial susceptible population
  S₀::Parameter{persons} = 3.0e8 ~ U(1.0e6,4.0e6)
  
  S₀::Initial = S₀
  
  # I₀ -- the initial infected population
  I₀::Parameter{persons} = 1.0 ~ U(1,1)
  
  I₀::Initial = I₀
  
  # R₀ -- the initial recovered population
  R₀::Parameter{persons} = 0.0 ~ U(0,4)
  
  R₀::Initial = R₀
end

Typing: begin
  Model = begin
    LabelledPetriNet{Symbol} begin 
      S(label=:Pop)
      T(label=:inf)
      T(label=:disease)
      T(label=:strata)
      I(is=:Pop,it=:inf)
      I(is=:Pop,it=:inf)
      I(is=:Pop,it=:disease)
      I(is=:Pop,it=:strata)
      O(os=:Pop,it=:inf)
      O(os=:Pop,it=:inf)
      O(os=:Pop,it=:disease)
      O(os=:Pop,it=:strata)
     end
  end
TypeMap = [
  S => Pop,
  I => Pop,
  R => Pop,
  inf => inf,
  rec => disease,]
end