function get_thermodynamic_constraints(N,varargin)
## Andrei Kramer <andreikr@kth.se>
##
## Usage: get_thermodynamic_constraints(N,[ParNames])
##
## Arguments
##
##        N: stoichiometric matrix of reaction network with mass action kinetics
## ParNames: cell array of strings. Contains the names of the equilibrium parameters, 
##           one for each reaction
##
## implementation of algorithm described in
##   Vlad, Marcel O., and John Ross. "Thermodynamically based constraints for rate coefficients of large biochemical networks." 
##   Wiley Interdisciplinary Reviews: Systems Biology and Medicine 1.3 (2009): 348-358.

if (nargin>1)
 knames=varargin{1};
else
 R=columns(N);
 knames=cell(R,1);
 for i=1:R
  knames{i}=sprintf("K(%i)",i);
 endfor
endif

l=false(1,R); 
A=[]; 
for i=1:length(l)
 B=cat(2,A,N(:,i)); 
 if rank(B)==min(size(B))
  A=B; 
  l(i)=true; 
 endif
endfor
j_K=[1:length(l)](l);
j_Z=[1:length(l)](!l);

r=false(rows(N),1);
C=[];
for i=1:length(r)
 B=cat(1,C,A(i,:)); 
 if rank(B)==min(size(B))
  C=B; 
  r(i)=true; 
 endif
endfor

k=rank(A);
i_K=([1:length(r)](r))(1:k);
i_Y=cat(2,([1:length(r)](r))(k+1:end),[1:length(r)](!r));

GKK=N(i_K,j_K);
GKZ=N(i_K,j_Z);
GYK=N(i_Y,j_K);
GYZ=N(i_Y,j_Z);

T=GKK\GKZ;

printf("K(i)=k_f(i)/k_b(i) [etc.]\n");
for i=1:length(j_Z)
 a=j_Z(i);
 printf("%s=1",knames{a});
 for j=1:length(i_K)
  b=i_K(j);
  if abs(t=T(j,i))>1e-7 # so !=0
   printf("*%s^{%g}",knames{b},t);
  endif
 endfor
 printf(";\n");
endfor
endfunction
