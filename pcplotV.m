function pcplotV(Sample,P,varargin)
  %% Usage: pcplot(Sample,P,[options])
  %% returns a figure handle to a parallel coordinate plot of a sample
  %% the lines are sorted by using their probability values P.
  %% Sample should be a list of column vectors, each representing one sampled point
  %% each column of Sample corresponds to one probability number in P
  %% size(Sample,2)==length(P);
  %% Sample has more columns than rows;
  %%
  %% Options: options.colormap -- colormap, default is bone(64);
  %%          options.names -- cell aray of names to be placed on the y ticks
  %%          
  assert(size(Sample,2)==size(P,2) && size(Sample,3)==size(P,3));
  sz=size(Sample);
  o=size(Sample,3);

  if (nargin>2)
    options=varargin{1};
  else
    options=struct(); % empty struct, defaults apply
    fprintf('using default color map: bone(64);\n');
    options.colormap=flipud(bone(64));
    yname=cell(sz(1),1);
    for i=1:sz(1)
      yname{i}=sprintf('RandomVariable%i',i);
    end%for
    options.names=yname;
  end%if
  
  if isfield(options,'sortmap')
    [~,I]=sort(options.sortmap(P),2);
  else
    [~,I]=sort(P,2);
  end%if
  %% deal with nd arrays:
  S=NA(sz); % same size as Sample
  for i=1:o
    Ii=I(1,:,i);
    S(:,:,i)=Sample(:,Ii,i);
    P(1,:,i)=P(1,Ii,i);
  end%for
  if o>1
    % transpose
    S=permute(S,[1,3,2]);
    P=permute(P,[1,3,2]);
    % reshape
    S=reshape(S,sz(1),[]);
    P=reshape(P,1,[]);
  end%if
  [m,n]=size(S);
  if (nargin>2)
    options=varargin{1};
  else
    options=struct(); % empty struct, defaults apply
    fprintf('using default color map: bone(64);\n');
    options.colormap=flipud(bone(64));
    yname=cell(m,1);
    for i=1:m
      yname{i}=sprintf('RandomVariable%i',i);
    end%for
    options.names=yname;
  end%if
  if isfield(options,'colormap')
    CMAP=options.colormap;
  else
    CMAP=flipud(bone(64));
  end%if
  colormap(CMAP);
  c=size(CMAP,1);
  r=[min(P),max(P)];
  caxis(r);
  fprintf('range: [%i,%i]\n',r);
  lsc=linspace(r(1),r(2),c);
  color_order=interp1(lsc,CMAP,P,'linear');
  if any(color_order(:)>1)
    color_order(color_order>1)=1; % why does this happen sometimes?
    warning('color_order > 1 detected (corrected).');
    color_order
  end%%if
  if any(color_order(:)<0)
    color_order(color_order<0)=0;
    warning('color_order < 0 detected (corrected).');
    color_order
  end%%if
  cla;
  hold on;
  set(gcf,'defaulttextinterpreter','none');
  set(gca,'ColorOrder',color_order);
  %%
  %% the plot command is below this line
  plot(S,[1:m]);
  %%
  ylim([0,m]+0.5);
  YL=get(gca,'ylabel');
  set(gca,'ytick',1:m);
  set(gca,'tickdir','out');
  set(gca,'yticklabel',[]);
  if isfield(options,'names')
    YLstring=get(YL,'string');
    YLpos=get(YL,'position');
    NameLabels=options.names;
    ytlh=text(YLpos(1)*ones(1,m),1:m,NameLabels);
    set(ytlh,'horizontalalignment','right','verticalalignment',
	'middle');
  end%if
  set(gca,'ygrid', 'on');
  set(gca,'gridcolor',[0.7,0.7,0.7]);
  set(gca,'gridlinestyle',':');
  box on;
  %%hold off;
end%%function
