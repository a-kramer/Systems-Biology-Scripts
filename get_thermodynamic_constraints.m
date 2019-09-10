function [LawText]=get_thermodynamic_constraints(N,varargin)
  ## Andrei Kramer <andreikr@kth.se>
  ##
  ## Usage: get_thermodynamic_constraints(N,[ParNames],[opt])
  ##
  ## Arguments
  ##
  ##        N: stoichiometric matrix of reaction network with
  ##           mass action kinetics
  ## ParNames: cell array of strings. Contains the names of the
  ##           equilibrium parameters; one for each reaction
  ##
  ## Result: this function just assumes that all reactions in N
  ##         are reversible and of type Mass Action. So, each
  ##         reaction is assumed to have a forward kinetic rate
  ##         coefficient k_f and a backward reaction rate
  ##         coefficiant k_b (sometimes also named k_r).
  ##         These define a dissociation constant KD=k_f/k_r.
  ##         The script then finds relationships between all KDs
  ##         and prints them on screen. By default, it uses the name
  ##         K(i) for the dissociation constant of the reaction
  ##         decribed by column i of the stoichiometry N.
  ##
  ## implementation of algorithm described in
  ##  [1] Vlad, Marcel O., and John Ross. "Thermodynamically based constraints for rate coefficients of large biochemical networks." 
  ##   Wiley Interdisciplinary Reviews: Systems Biology and Medicine 1.3 (2009): 348-358.
 

  R=columns(N); # number of reactions
  n=rows(N);
  k=rank(N);

  if nargin>2 && isstruct(varargin{2});
    opt=varargin{2};
  else
    opt=struct(); # defaults
  endif

  if nargin>1 && not(isempty(varargin{1})) && iscell(varargin{1}) && length(varargin{1})>1
      knames=varargin{1};
      assert(R==length(knames));
  else
    knames=cell(R,1);
    if isfield(opt,'fractions') && opt.fractions
      for i=1:R
	knames{i}=sprintf("(kf_%i/kr_%i)",i,i);
      endfor
    else
      for i=1:R
	knames{i}=sprintf("K%i",i);
      endfor
    endif
  endif
  l=false(1,R); 
  A=[]; 
  for i=1:R
    B=cat(2,A,N(:,i)); 
    if rank(B)==min(size(B))
      A=B; 
      l(i)=true; 
    endif
  endfor
  j_K=find(l);
  j_Z=find(not(l));
  
  r=false(n,1);
  C=[];
  for i=1:n
    B=cat(1,C,A(i,:)); 
    if rank(B)==min(size(B))
      C=B; 
      r(i)=true; 
    endif
  endfor
  
  i_K=find(r,k);
  i_Y=cat(2,find(r')(k+1:end),find(not(r')));
  
  GKK=N(i_K,j_K); %
  GKZ=N(i_K,j_Z);
  GYK=N(i_Y,j_K);
  GYZ=N(i_Y,j_Z);
  
  T=GKK\GKZ;
  display(size(T))
  ## the assumption is that if a reaction i does not have a simple kf
  ## and kb, then the K of that reaction K(i) does not exist in that
  ## simple form. Then K(i) may not participate in any relation
  ## printed below, those lines should be discarded.
  printf("K(i)=kf(i)/kb(i) [etc.]\n"); % [1] eq. (4)

  %% the following block is an interpretation of [1] eq. (45)
  L=length(j_Z);
  LawText=cell(L,1);
  for i=1:L
    a=j_Z(i);
    S=sprintf("%s=",knames{a});
    initial=true;
    for j=1:k
      b=j_K(j);
      if abs(t=T(j,i))>1e-7 # so, not 0
	Et=sprintf('^(%i)',t);
	S=strcat(S,sprintf("%s%s%s",merge(initial,'','*'),knames{b},merge(not(t==1),Et,'')));
	initial=false;
      endif
    endfor
    S=strcat(S,sprintf(";\n"));
    printf(S);
    LawText{i}=S;
  endfor
  if isfield(opt,'transform') && opt.transform
    LawText=transform(LawText);
  endif
endfunction


function [LawText]=transform(LawText)
  L=length(LawText);
  for i=1:L
    S=LawText{i};
    S=regexprep(S,'\((\w+)/(\w+)\)\s*=\s*(.*);','$1=($3)*($2)');
    S=regexprep(S,'\((\w+)/(\w+)\)\^[\{\(]-1[\}\)]','($2/$1)'); # in case of normal parnetheses
    S=regexprep(S,'\((\w+)/(\w+)\)\^[\{\(]-(\d+)[\}\)]','($2/$1)^($3)'); # in case of normal parnetheses
    LawText{i}=S;
  endfor
endfunction
