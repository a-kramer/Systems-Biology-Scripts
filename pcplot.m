function pcplot(Sample,P,varargin)
% Usage: pcplot(Sample,P,varargin)
% returns a figure handle to a parallel coordinate plot of a sample
% the lines are sorted by using their probability values P.
% Sample should be a list of column vectors, each representing one sampled point
% each column of Sample corresponds to one probability number in P
% columns(Sample)==length(P);
 hold on;
 [m,n]=size(Sample);
 [s,I]=sort(P);
 if (nargin>2)
  CMAP=varargin{1};
 else
  CMAP=flipud(bone(64));
 endif
 colormap(CMAP);
 c=rows(CMAP);
 printf("range: [%i,%i]\n",s(1),s(n));
 lsc=linspace(s(1),s(n),c);
 color_order=interp1(lsc,CMAP,s,"*linear");
 set(gca,"ColorOrder",color_order);
 plot(Sample(:,I));
 hold off;
endfunction
