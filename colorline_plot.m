function [h,lh]=colorline_plot(x,Sample,P,varargin)
  ## Usage: colorline_plot(x,Sample,P,[options])
  ##
  ## x maps to rows of Sample (lines): x(i) → Sample(i,:)
  ##
  ## Sample is a set of sampled one dimensional lines Sample(:,j),
  ## where j enumerates sample members; Each line has a
  ## probability/weight P(j);
  ##
  ## columns(Sample)==length(P); length(x)==rows(Sample);
  ##
  ## The lines are coloured using the range of these weights; from
  ## min(P) to max(P). The lines will be reordered such that the most
  ## probable line (heighest weight) is drawn last and covers the less
  ## probable lines.
  ##
  ## the last argument is an optional options struct with the fields:
  ## options.{colormap,legend}, where «colormap» is applied to the lines
  ## using the "ColorOrder" property of the axis object and «legend» is
  ## applied to the last line (highest weight).
    assert(columns(Sample)==columns(P) && size(Sample,3)==size(P,3));
  sz=size(Sample);
  o=size(Sample,3);

  if (nargin>2)
    options=varargin{1};
  else
    options=struct(); # empty struct, defaults apply
    printf('using default color map: bone(64);\n');
    options.colormap=flipud(bone(64));
  endif
  
  if isfield(options,"sortmap")
    [~,I]=sort(options.sortmap(P),2);
  else
    [~,I]=sort(P,2);
  endif
  ## deal with nd arrays:
  S=NA(sz); # same size as Sample
  for i=1:o
    Ii=I(1,:,i);
    S(:,:,i)=Sample(:,Ii,i);
    P(1,:,i)=P(1,Ii,i);
  endfor
  if o>1
    # transpose
    S=permute(S,[1,3,2]);
    P=permute(P,[1,3,2]);
    # reshape
    S=reshape(S,sz(1),[]);
    P=reshape(P,1,[]);
  endif
  [m,n]=size(S);
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
    CMAP=flipud(bone(64));
  endif
  colormap(CMAP);
  c=size(CMAP,1);
  r=[min(P),max(P)];
  caxis(r);
  printf('range: [%i,%i]\n',r);
  lsc=linspace(r(1),r(2),c);
  color_order=interp1(lsc,CMAP,P,'linear');
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
  set(gcf,'defaulttextinterpreter','none');
  set(gca,'ColorOrder',color_order);
  h=plot(x,S);
  if (isfield(options,"legend") && ischar(options.legend))
    lh=legend(h(end),options.legend);
  endif
  set(gca,"ygrid", "on");
  set(gca,"gridcolor",[0.7,0.7,0.7]);
  set(gca,"gridlinestyle",":");
  box on;
endfunction
