# Generic Solver for Dynamic Portfolio Choice Models

In discrete time, a way to solve dynamic portfolio choice problems is value function iteration, and the computational complexity of this approach grows exponentially with the number of state variables.
This is known as the *curse of dimensionality*.

This solver follows a generic solution methodology that copes with the curse of dimensionality using sparse grid interpolation to interpolate the value function and optimal policies.
The approach followed is general enough to be applicable to a broad class of dynamic portfolio choice models when the policy variables are continuous.

The solver has been written in the course of the following dissertations:

* Julian Valentin (2019), “B-Splines for Sparse Grids: Algorithms and Application to Higher-Dimensional Optimization,” PhD thesis, University of Stuttgart ([available at arXiv](https://arxiv.org/abs/1910.05379))
* Peter Schober (2019), “Advanced Numerical Methods for Dynamic Portfolio Choice Models in Discrete Time,” PhD thesis, Goethe University Frankfurt

## License

The project is licensed under the 3-clause BSD-license contained in `LICENSE.md`, with the following exceptions:

* `lib/sgppInterface.mex[wa]64`: These files are binaries from the software SG++ developed 2008-today by The SG++ Project and its contributors, see [sgpp.sparsegrids.org](https://sgpp.sparsegrids.org/) and [github.com/SGpp/SGpp](https://github.com/SGpp/SGpp). The license is contained in `SGpp.md`.
* `lib/tsgMakeQuadrature.mex[wa]64`: These files are binaries from the software TASMANIAN, UT-BATTELLE, LLC, see [tasmanian.ornl.gov](https://tasmanian.ornl.gov/) and [github.com/ORNL/Tasmanian](https://github.com/ORNL/Tasmanian). The license is contained in `TASMANIAN.md`.
