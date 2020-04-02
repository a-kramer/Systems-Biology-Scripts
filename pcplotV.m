function pcplotV(Sample,P,varargin)
  %% Usage: pcplot(Sample,P,[options])
  %% returns a figure handle to a parallel coordinate plot of a sample
  %% the lines are sorted by using their probability values P.
  %% Sample should be a list of column vectors, each representing one sampled point
  %% each column of Sample corresponds to one probability number in P
  %% columns(Sample)==length(P);
  %% Sample has more columns than rows;
  %%
  %% Options: options.colormap -- colormap, default is bone(64);
  %%          options.names -- cell aray of names to be placed on the y ticks
  %%          
  assert(columns(Sample)==columns(P) && size(Sample,3)==size(P,3));
  sz=size(Sample);
  o=size(Sample,3);
  if (nargin>2)
    options=varargin{1};
  else
    options=default_options(sz(1));
  endif
  if isfield(options,"sortmap")
    [~,I]=sort(options.sortmap(P),2);
  else
    [~,I]=sort(P,2);
  endif
  [S,P]=from_nd_array(Sample,P)
  [m,n]=size(S);
  CMAP=options.colormap;
  colormap(CMAP);
  color_order=configure_colors(CMAP,min(P),max(P));
  cla;
  hold on;
  set(gcf,'defaulttextinterpreter','none');
  set(gca,'ColorOrder',color_order);
  %%
  plot(S,[1:m]);
  %%
  ylim([0,m]+0.5);
  set(gca,"ytick",1:m);
  Labels(options.names);
  set(gca,"ygrid", "on");
  set(gca,"gridcolor",[0.7,0.7,0.7]);
  set(gca,"gridlinestyle",":");
  box on;
  %%hold off;
endfunction

function [color_order]=configure_colors(CMAP,minP,maxP)
  c=size(CMAP,1);
  r=[minP,maxP];
  caxis(r);
  printf('range: [%i,%i]\n',r);
  lsc=linspace(r(1),r(2),c);
  color_order=fix_colormap(interp1(lsc,CMAP,P,'linear'));
endfunction

function Labels(names)
  set(gca,"tickdir","out");
  set(gca,"yticklabel",[]);
  YL=get(gca,'ylabel');
  YLstring=get(YL,'string');
  YLpos=get(YL,'position');
  NameLabels=names;
  ytlh=text(YLpos(1)*ones(1,m),1:m,NameLabels);
  set(ytlh,'horizontalalignment','right','verticalalignment','middle');
endfunction

function [options]=default_options(m)
  ## Usage: [options]=default_options(m)
  ##  m: number of parameters
    options=struct(); 
    printf('using default color map: bone(64);\n');
    options.colormap=flipud(bone(64));
    yname=cell(m,1);
    for i=1:m
      yname{i}=sprintf("RandomVariable%i",i);
    endfor
    options.names=yname;
endfunction
