function [fh]=colorline_plot(x,Sample,P,varargin)
# Usage: colorline_plot(x,Sample,P,...)
# Sample is a set of sampled one dimensional lines Sample(:,i), each having a probability/weight P(i)
# columns(Sample)==length(P);
# The lines are coloured using the range of these weights; from min(P) to max(P).
# The lines will be reordered such that the most probable line (heighest weight) is drawn last and covers the less probable lines.
#
 set(gcf, 'DefaultLineLineWidth', 3);
 hold on;
 [m,n]=size(Sample);
 [s,I]=sort(P);
 if (nargin>3)
  CMAP=varargin{1};
 else
  CMAP=flipud(colormap('bone'));
 endif
 c=rows(CMAP);
 printf("range: [%i,%i]\n",s(1),s(n));
 lsc=linspace(s(1),s(n),c);
 color_order=interp1(lsc,CMAP,s,"*linear");
 set(gca,"ColorOrder",color_order);
 plot(x,Sample(:,I));
 hold off;
endfunction
