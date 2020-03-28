function pcplot(Sample,P,varargin)
% Usage: pcplot(Sample,P,[colormap])
% returns a figure handle to a parallel coordinate plot of a sample
% the lines are sorted by using their probability values P.
% Sample should be a list of column vectors, each representing one sampled point
% each column of Sample corresponds to one probability number in P
% columns(Sample)==length(P);
 hold on;
 [m,n]=size(Sample);
 assert(n==length(P));
 if (nargin>2)
   options=varargin{1};
 else
   options=struct(); # empty struct, defaults apply
   printf('using default color map: bone(64);\n');
   options.colormap=flipud(bone(64));
   yname=cell(sz(1),1);
   for i=1:sz(1)
     yname{i}=sprintf("RandomVariable%i",i);
   endfor
   options.names=yname;
 endif
 
 if isfield(options,"sortmap")
   [~,I]=sort(options.sortmap(P),2);
 else
   [~,I]=sort(P,2);
 endif
 if isfield(options,"colormap")
   CMAP=options.colormap;
 else
   CMAP=flipud(bone(64));
 endif
 
 colormap(CMAP);
 r=[min(P),max(P)];
 caxis(r);

 c=rows(CMAP);
 printf("range: [%i,%i]\n",r);

 lsc=linspace(r(1),r(2),c);
 color_order=interp1(lsc,CMAP,P,'linear');
  if any(color_order(:)>1)
    color_order(color_order>1)=1; # why does this happen sometimes?
    warning('color_order > 1 detected (corrected).');
    color_order
  endif
  if any(color_order(:)<0)
    color_order(color_order<0)=0;
    warning('color_order < 0 detected (corrected).');
    color_order
  endif 
 set(gca,"ColorOrder",color_order); 
 plot(Sample(:,I));
 %%
 xlim([0,m]+0.5);
 XL=get(gca,'xlabel');
 set(gca,"xtick",1:m);
 set(gca,"tickdir","out");
 set(gca,"xticklabel",[]);
 if isfield(options,"names")
   XLstring=get(XL,'string');
   XLpos=get(XL,'position');
   NameLabels=options.names;
   xtlh=text(1:m,XLpos(2)*ones(1,m),NameLabels);
   set(xtlh,'horizontalalignment','left','verticalalignment',...
       'middle','rotation',-45,"interpreter","none");
 endif
 ##set(gca,"grid", "on");
 grid on;
 set(gca,"gridcolor",[0.7,0.7,0.7]);
 set(gca,"gridlinestyle",":");
 box on;
 hold off;
endfunction
