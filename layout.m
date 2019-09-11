function [n,m]=layout(N)
  %%
  %% Usage: [n,m]=layout(N)
  %%   divides N subplots into an n×m layout,
  %%   where n*m=N
  f=factor(N);
  lf=length(f);
  nf=floor(lf/2);
  mf=lf-nf;
  [n,m]=deal(prod(f(1:nf)),prod(f(nf+1:lf)));  
end%function
