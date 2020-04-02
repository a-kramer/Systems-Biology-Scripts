function [h]=boxplot(x,y,varargin)
  ## Usage: boxplot(x,y,KEY,VALUE)
  ##
  n=nargin-2; # (key,value) pairs
  p=[0,0.25,0.5,0.75,1]; #default
  bc="blue";
  mc="red";
  for i=1:2:n
    switch(varargin{i})
      case {"quantile","Quantile","p","P"}
	p=varargin{i+1};
	assert(length(p)==5);
      case {"median color"}
	mc=varargin{i+1};
	assert(isvector(mc) && length(mc)==3);
      case {"box color"}
	bc=varargin{i+1};
	assert(isvector(bc) && length(bc)==3);
      otherwise
	error("unknown option: %s",varargin{1});
    endswitch
  endfor
  assert(isvector(x) && ismatrix(y) &&length(x)==size(y,2));
  Q=quantile(y,p)';
  h=struct();
  D=diff(x);
  D=cat(2,D,D(end));
  clf;
  hold on;
  for j=1:size(y,2)
    d=D(j)*0.4;
    h(j).whisker=plot(x(j)*ones(1,2),Q(j,[1,5]),"color",bc);
    h(j).box=patch(x(j)+[-d,+d,+d,-d],[Q(j,[2,2]),Q(j,[4,4])],"edgecolor",bc,"facecolor","white");
    h(j).median=plot(x(j)+[-d,+d],Q(j,[3,3]),"color",mc);
  endfor
  hold off;
endfunction
