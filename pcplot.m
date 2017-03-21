function pcplot(Sample,P,varargin)
% Usage: pcplot(Sample,P,varargin)
% parallel coordinate plot of a sample, without y-axis scaling.
% The lines are sorted by using their probability values P.
% Sample should be a list of column vectors, each representing one sampled point
% each column of Sample corresponds to one probability/weight number in P
% columns(Sample)==length(P);
% P can be a weight of any kind, also logarithmic (negative values are accepted).
 set(gcf, 'DefaultLineLineWidth', 3);
 hold on;
 [m,n]=size(Sample);
 [s,I]=sort(P);
 if (nargin>2)
  CMAP=varargin{1};
 else
  CMAP=flipud(colormap('bone'));
 end%if
 c=rows(CMAP);
 printf("range: [%i,%i]\n",s(1),s(n));
 lsc=linspace(s(1),s(n),c);
 color_order=interp1(lsc,CMAP,s,"*linear");
 set(gca,"ColorOrder",color_order);
 plot(Sample(:,I));
 hold off;
end%function
