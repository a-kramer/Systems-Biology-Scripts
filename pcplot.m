function pcplot(Sample,P,varargin)
  ## Usage: pcplot(Sample,P,[colormap])
  ## returns a figure handle to a parallel coordinate plot of a sample
  ## the lines are sorted by using their probability values P.
  ## Sample should be a list of column vectors, each representing one sampled point
  ## each column of Sample corresponds to one probability number in P
  ## columns(Sample)==length(P);
  hold on;
  sz=size(Sample);
  assert(sz(2)==length(P));
  if (nargin>2)
    options=varargin{1};
  else
    options=default_options(sz(1));
  endif
  assert(isstruct(options));
  if isfield(options,"sortmap")
    [~,I]=sort(options.sortmap(P),2);
  else
    [~,I]=sort(P,2);
  endif
  [S,P]=from_nd_array(Sample,P,I);
  CMAP=options.colormap;
  colormap(CMAP);
  color_order=pcplot_configure_colors(CMAP,P);
  set(gca,"ColorOrder",color_order); 
  plot(Sample(:,I));
  %%
  xlim([0,sz(1)]+0.5);
  Labels(options.names);
  grid on;
  set(gca,"gridcolor",[0.7,0.7,0.7]);
  set(gca,"gridlinestyle",":");
  box on;
  hold off;
endfunction


function Labels(names)
  m=length(names);
  XL=get(gca,'xlabel');
  set(gca,"xtick",1:m);
  set(gca,"tickdir","out");
  set(gca,"xticklabel",[]);
  XLstring=get(XL,'string');
  XLpos=get(XL,'position');
  NameLabels=names;
  xtlh=text(1:m,XLpos(2)*ones(1,m),NameLabels);
  set(xtlh,'horizontalalignment','left','verticalalignment',...
      'middle','rotation',-45,"interpreter","none");
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
