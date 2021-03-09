# Systems Biology Scripts

Scripts that are useful for working with certain file types and
problems frequently encountered in _systems biology_. These scripts
may be more generally useful.

Some of the functions in this collection are undocumented because
their usefulness to others is not yet certain, or they may be still in
an early stage of development.

## Kernel Density Estimation

The function in `mkde.m` returns a function handle to a multivariate
(unimodal) sample's kernel density estimate.

```matlab
 p=mkde(X);
 p(x) % probability of x estimated from sample X.
```

This can work well up to a point (dimensionality of X, one mode). For
very high dimensional spaces (>20) a different approach is necessary.

The function `mkde_cl(X,k)` (in `mkde_cl.m`) tries to address the
problem of modes by doing a clustering first.

## Boxplot

GNU Octave doesn't have a good/working boxplot function. The function
in `boxplot.m` is a very simple implementation that makes working with
boxplots easier. It does not plot any «outliers» (only the results of
the quantile function).

The main arguments are:

```
h=boxplot(x,y,[KEY,VALUE])
```
where `y` is a matrix of sampled values and `x` is a position.


1. the returned handle `h` is a struct-array of handles for each box-whisker
    - `.median` is a handle for the median line
	- `.box` is a handle for the entire box
	- `.whisker` is a handle to the whisker line
2. the function takes an `x` position argument
    - this means that the boxes can have irregular spaces between them
	- for example, a time dependent stochastic signal can be plotted as a series of boxes: `boxplot(t,y_of_t)`
3. the positioning variable `x` makes it easy to manually plot various sets of boxes together

For two data-sets: `y1` and `y2`

```matlab
hy1=boxplot(x-0.1,y1,"face color",[0.8,0.8,1.0]);
hold on;
hy2=boxplot(x+0.1,y2,"face color",[0.9,0.8,0.7]);
```

Currently, the boxes don't have a legend entry associated with them.
The appearance can be fine-tuned using _key_ and _value_ pairs.

## Parallel Coordinate Plot (simplified) 

The function in `pcplot.m` plots each sampled point as a line with
each parameter's vector-index on the x-axis.  This is similar to a
parallel coordinate plot but _without_ y-axis resizing/scaling or
shifting.  Each line is coloured according to the attached probability
density value. These values are allowed to be negative in case they
are log-probabilities.

## Colorline Plot

The function `colorline_plot.m`
similar to pcplot but accepts an additional x-axis
vector. It will plot model trajectories coloured the same way as in
`pcplot`.

## Thermodynamic Constraints

The function in `get_thermodynamic_constraints.m` calculates the relationships of equilibrium constants as described here:
```
Vlad, Marcel O., and John Ross. "Thermodynamically based constraints for rate coefficients of large biochemical networks." 
Wiley Interdisciplinary Reviews: Systems Biology and Medicine 1.3 (2009): 348-358.
```

## Conservation Laws 

The function in `conservation_laws.m` prints particle conservation
laws in systems biology models. This function constructs a
stoichiometric matrix given a function that maps fluxes onto the
ode-rhs vectro field.

## Print with Error (concise error notation)

The function in `pwe.m` prints a value and its uncertainty using
concise error notation, like this:

```matlab
%1.0045(38) = (1.0045 ± 0.0038) × 10⁰
 pwe(1.00452193847298,0.003820934870293)
 1.0045(38) × 10^{0}
```

which saves space with accurate measurements.


