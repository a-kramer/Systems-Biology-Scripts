# scripts
Scripts that are useful for the processing of parameter samples of dynamic models

## mkde.m
returns a function handle to a multivariate sample's kernel density estimate.
```octave
 p=mkde(X);
 p(x) # probability of x estimated from sample X.
```
## pcplot.m
plots each sampled point as a line with each parameter's
vector-index on the x-axis.  This is similar to a parallel coordinate
plot but without y-axis resizing/scaling.  Each line is coloured
according to the attached probability density value. These values are
allowed to be negative in case they are log-probabilities.

## colorline_plot.m
similar to pcplot but accepts an additional x-axis
vector. It will plot model trajectories coloured the same way as in
`pcplot`.

## pwe.m
prints a value and it's uncertainty using concise error notation, like this:
```octave
#1.0045(38) = (1.0045 ± 0.0038) × 10⁰
 pwe(1.00452193847298,0.003820934870293)
 1.0045(38) × 10^{0}
```    
which saves space with accurate measurements.