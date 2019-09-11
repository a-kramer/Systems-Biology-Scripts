function [fh]=interpolated_colorline_plot(xi,Sample,P,varargin)
% Usage: colorline_plot(xi,Sample,P,...)
% Sample is a set of sampled one dimensional lines Sample(:,i), each having a probability/weight P(i)
% size(Sample,2)==length(P);
% The lines are coloured using the range of these weights; from min(P) to max(P).
% The lines will be reordered such that the most probable line (heighest weight) is drawn last and covers the less probable lines.
%
 hold on;
 [m,n]=size(Sample);
 [s,I]=sort(P);
 ni=length(xi);
 x=linspace(xi(1),xi(ni),n);
 xi=reshape(xi,ni,1);
 yi=interp1(x,Sample,xi,'*spline','extrap');
 size(yi)
 if (nargin>3)
  CMAP=colormap(varargin{1});
 else
  CMAP=colormap(flipud(bone()));
 end%if
 c=size(CMAP,1);
 fprintf('range: [%i,%i]\n',s(1),s(n));
 lsc=linspace(s(1),s(n),c);
 color_order=interp1(lsc,CMAP,s,'*linear');
 set(gca,'ColorOrder',color_order);
 plot(xi,yi);
 hold off;
end%function
