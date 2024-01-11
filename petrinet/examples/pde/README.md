This directory includes subdirectories (noted below) for multiple PDE problems that are encoded as Petri nets.  

- `halfar`: ice dome model 
- `advection`: advection model for incompressible flows 

The files in each subdirectory use the naming scheme, as follows:

`{problem}_{derivative}_{dimensions}_{boundary_slope}_{num_disc}.json`

where 

- `problem`: the name of the problem (e.g., `advection`)
- `derivative`: the method used to compute spatial derivatives (e.g., `forward`, `backward`, and `centered`)
- `dimensions`: the number of spatial dimensions (1, 2, or 3)
- `boundary_slope`: the coefficient for boundary conditions, expressed as `u(x, t) = kt`, where `k = boundary_slope`, `t` is the time (relative to starting time at 0), `u` is a state variable, and `x` is a boundary position.
- `num_disc`: the number of discrete points in each dimension (e.g., if `dimension = 2` and `num_disc = 5`, then there will be `5^2 = 25` positions, not including boundaries).
 
The generator for these instances is currently available [here](https://github.com/siftech/funman/blob/pde-amr-examples/auxiliary_packages/funman_demo/scripts/generate-pde-amr.py), and a notebook illustrating the results of FUNMAN analyzing the models is available [here](https://github.com/siftech/funman/blob/pde-amr-examples/notebooks/pde_as_petrinet.ipynb).

---
Authored by dbryce@sift.net and dmosiphir@sift.net