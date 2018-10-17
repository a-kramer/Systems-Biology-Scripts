function pcplotV(Sample,P,varargin)
% Usage: pcplot(Sample,P,[colormap])
% returns a figure handle to a parallel coordinate plot of a sample
% the lines are sorted by using their probability values P.
% Sample should be a list of column vectors, each representing one sampled point
% each column of Sample corresponds to one probability number in P
% columns(Sample)==length(P);
% Sample has more columns than rows;
 [m,n]=size(Sample);
 assert(n==length(P),true);
 [s,I]=sort(P);
 if (nargin>2)
   options=varargin{1};
 else 
   options=struct(); # empty struct, defaults apply
   printf('using default color map: bone(64);\n');
   options.colormap=flipud(bone(64));
   yname=cell(m,1);
   for i=1:m
     yname{i}=sprintf("RandomVariable%i",i);
   endfor
   options.names=yname;
 endif
 if isfield(options,"colormap")   
   CMAP=options.colormap;
 else
   # in case an options argument was actually supplied, but doesn't contain this option.
   CMAP=flipud(bone(64));
 endif
 colormap(CMAP);
 c=size(CMAP,1);
 printf('range: [%i,%i]\n',s(1),s(n));
 lsc=linspace(s(1),s(n),c);
 color_order=interp1(lsc,CMAP,s,'linear');
 if any(color_order(:)>1)
   color_order(color_order>1)=1; # why does this happen sometimes?
   warning('color_order > 1 detected (corrected).');
   color_order
 end%if
 if any(color_order(:)<0)
   color_order(color_order<0)=0;
   warning('color_order < 0 detected (corrected).');
   color_order
 end%if
 cla;
 hold on;
 set(gca,'ColorOrder',color_order); 
 plot(Sample(:,I),[1:m]);
 ylim([0,m]+0.5);
 YL=get(gca,'ylabel');
 set(gca,"ytick",1:m);
 set(gca,"tickdir","out");
 set(gca,"yticklabel",[]);
 if isfield(options,"names")
   YLstring=get(YL,'string');
   YLpos=get(YL,'position');
   NameLabels=options.names;
   ytlh=text(YLpos(1)*ones(1,m),1:m,NameLabels);
   set(ytlh,'horizontalalignment','right','verticalalignment','middle');
 endif
 set(gca,"ygrid", "on");
 set(gca,"gridcolor",[0.7,0.7,0.7]);
 set(gca,"gridlinestyle",":");
 box on;
 hold off;
end%function
