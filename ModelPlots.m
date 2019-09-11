fprintf('plot related functions that concern SBtab model storage.\n');

function [names,x0]=get_ode_model_names(vf_file)
  assert(exist(vf_file,'file'));
  f=fileread(vf_file);
  vf=strsplit(f,'\n');
  NM=regexp(vf,'^\\s*<StateVariable Name=\'(?<name>[^\']+)\'.*DefaultInitialCondition=\'(?<InitialCondition>[^\']+)\'','names');

  names=cellfun(@(c) c.name,NM,'UniformOutput',false);
  i=cellfun(@isempty,names);
  names=names(not(i));
  %% these are the initial conditions that make it into the model
  %% file, excluding the ones that were turned into Mass Conservation
  %% Expressions
  x0=cellfun(@(c) str2double(c.InitialCondition),NM(not(i)));
end%function

function [f]=plot_trajectories(t,X,names)
  [M,IM]=max(X);
  nt=length(t);
  [cluster.idx, cluster.center, cluster.sumd, cluster.dist]=kmeans(log(abs(M)+eps)',NC=25);
  [n,m]=layout(NC);
  f=figure(); clf;
  for j=1:NC
    subplot(n,m,j); cla;
    sub_j=(cluster.idx==j);
    state_t=X(:,sub_j);
    %%[max_state,max_t]=max(state_t);
    %%max_t=merge(max_t==1,nt,max_t);
    Legend=names(sub_j);
    max_state=state_t(nt,:);
    max_t=ones(1,length(Legend))*nt;
    plot(t,state_t,'-;;');
    if not(isempty(names))
      text(t(max_t),max_state,Legend,'horizontalalignment','left','verticalalignment','middle');
    end%if
    xlabel('t');
    xlim([-5 max(t)*1.3]);
    ylabel('state variables');
  end%for
end%function

function [f]=plot_pairwise_comparison(t,X,names,varargin)
  assert(iscell(X) && length(X)>=2);
  assert(iscell(names) && length(names)>=2);
  nx=columns(X{1});
  F=gcf();
  f=F+[1:nx];
  for j=1:nx
    figure(f(j)); clf;
    sbtab_name=names{1}{j};
    m=strcmp(names{2},sbtab_name);
    k=find(m,1);
    if isempty(k)
      fprintf('Compound %s from SBtab file was not found in reference simulation struct.\n',sbtab_name);
      %%assert(not(isempty(k)));
      k=j;
      ref_name='could not find in «reference»';
    else
      ref_name=names{2}{k};
    end%if
    Label={sbtab_name,ref_name};
    l=[j,k];
    for i=1:2
      subplot(1,2,i);
      plot(t{i},X{i}(:,l(i)),'-;;');
      xlabel('t in s');
      ylabel(sprintf('[%s] in nM',Label{i}));
      if (nargin>=4)
	title(sprintf('%s simulation',varargin{i}));
      end%if
    end%for
    a=axis();
    subplot(1,2,1);
    axis(a);
  end%for
end%function

function show_state_variables(ivp,ref,state_vars,compounds)
  if not(exist('kmeans'))
    pkg load statistics
  end%if

  nE=length(ivp);
  assert(nE==length(ref));
  for i=1:nE
    n_cX=columns(ivp(i).X);
    n_sv=length(state_vars);
    
    Label=genvarname(ivp(i).tag);
    trajectory_hash=ivp(i).hash;
    if not(exist(Label,'dir'))
      system(sprintf('mkdir './%s'',Label));
    end%if
    
    X=ivp(i).X;
    t=ivp(i).t;
    if (size(X,2)!=length(state_vars))
      fprintf('size(X,2): %i, whereas length(state_vars): %i\n',size(X,2),length(state_vars));
    end%if
    fprintf('state var names:'); fprintf(' «%s»',state_vars{:}); fprintf('\n');
    f=cell(3,1);
    f{1}=plot_trajectories(t,X,state_vars);
    if isstruct(ref)
      f{2}=plot_trajectories(ref(i).t,ref(i).species,ref(i).species_name);
      f{3}=plot_pairwise_comparison({t,ref(i).t},{X,ref(i).species},{state_vars,ref(i).species_name},'vfgen/GNU Octave','Simbiology/Matlab');
    end%if
    for k=1:2
      figure(f{k});
      set(gcf,'paperunits','centimeters');
      set(gcf,'papersize',PS=4*[30,20]);
      set(gcf,'paperposition',[0,0,PS]);
      out_file_name=sprintf('./%s/MGluR_print_Simulation_%s_%s_hash_%s.png',Label,merge(k==1,'octave_vfgen','reference'),Label,trajectory_hash);
      conditionally_print(f{k},out_file_name);
    end%for

    for j=1:n_cX
      cf=f{3}(j);
      figure(cf);
      set(gcf,'paperunits','centimeters');
      set(gcf,'papersize',PS=[20,10]);
      set(gcf,'paperposition',[0,0,PS]);
      out_file_name=sprintf('./%s/MGluR_Compound_%i_of_%i_%s_hash_%s.png',Label,j,n_cX,state_vars{j},trajectory_hash);
      conditionally_print(cf,out_file_name);
    end%for
  end%for
  pkg unload statistics
end%function

function conditionally_print(fh,out_file_name)
  figure(fh);
  if exist(out_file_name,'file')
    fprintf('%s already exists, skipping.\n',out_file_name);
  else
    print('-dpng',out_file_name);
  end%if
  close(fh);
end%function

function ivp=get_model_outputs(ivp,out,out_name)
  nE=length(ivp);
  ny=length(out_name);
  for j=1:nE
    t=ivp(j).t;
    nt=length(t);
    X=ivp(j).X;
    Y=NA(nt,ny);
    for i=1:nt
      y=out(t(i),X(i,:),ivp(j).p);
      Y(i,:)=reshape(y,1,[]);
      if any(isnan(y))
	warning('nan detected');
	display(y);
      end%if
      ivp(j).Y=Y;
    end%for
  end%for  
end%function

function show_outputs(ivp,Ref,E,out_name)
  %%[n,m]=layout(ny);
  nE=length(ivp);
  assert(nE==length(Ref));
  for i=1:nE
    for j=1:ny
      figure((i-1)*ny+j); clf();
      plot(t=ivp(i).t,Z=ivp(i).Z(:,j),';VFGEN/GNU Octave;','linewidth',1.5); hold on;
      xlim([-2,max(t)]);
      if any(j==E(i).MeasuredOutput)
	o=E(i).MeasuredOutput;
	plot(Ref(i).t,Ref(i).output,':;Simbiology/Matlab;','linewidth',2.5);      
	e1=errorbar(E(i).time,E(i).data(:,o),E(i).stdv(:,o),'~');
	set(e1,'linestyle','none');
      end%if
      cn=strrep(out_name{j},'_mon','');
      c=strcmp(cn,Ref(i).species_name);
      if any(c)
	plot(Ref(i).t,Ref(i).species(:,c),'-;Simbiology/Matlab;');
      end%if
      hold off;
      xlabel('t');
      ylabel(out_name{j});
      out_file_name=sprintf('./%s/MGluR_OutputFunction_%i_%s_hash_%s.png',ivp(i).tag,j,out_name{j},ivp(i).trajectory_hash);
      %%set(gca,'position',[0.08,0.1,0.87,0.87]);
      set(gca,'fontname','Fira Sans Book');
      set(gca,'fontsize',11);
      set(gcf,'paperunits','pixels');
      set(gcf,'papersize',PS=[1600,1200]);
      set(gcf,'paperposition',[0,0,PS]);
      set(gcf,'paperorientation','landscape');
      conditionally_print(gcf,out_file_name);
      close(gcf);
    end%for
  end%for
end%function

function [ivp]=normalisation(ivp,Norm)
  assert(isstruct(ivp));
  nE=length(ivp);
  o=isfinite(Norm.O);
  if not(isempty(Norm.E))
    for i=1:nE
      if isna(Norm.T(i))
	if iscell(t)
	  nt=length(t{i});
	else
	  nt=length(t);
	end%if
	T=1:nt; %% do it point by point
      else
	nt=1;
	T=Norm.T(i); %% normalisation time point
      end%if
      if not(isna(j=Norm.E(i)))
	if (rows(ivp(i).Y)!=rows(ivp(j).Y))
	  T=T(end%); %% override previous choice if there is a length mismatch
	end%if
	ivp(i).Z=ivp(i).Y;
	ivp(i).Z(o)=bsxfun(@rdivide,ivp(i).Y(o),eps+ivp(j).Y(T,o));
      end%if
    end%for
  end%if
end%function

function [X,T]=forward_simulation(vf,jac,x0,t,varargin)
  method='default';
  if (nargin>4)
    method=varargin{1};
  end%if
  if (nargin>5)
    T_CRIT=varargin{2};
  end%if
  switch(method)
    case {'lsode','default'}
      lsode_options('integration method','bdf');
      lsode_options('absolute tolerance',1e-6);
      lsode_options('relative tolerance',1e-6);
      X=lsode({vf,jac},x0,t,T_CRIT);
      T=t;
    case {'ode45'}
      opt=odeset('Jacobian',jac);
      [T,X]=ode45(vf,[t(1), 0, t(end%)],x0,opt);
    case {'ode23'}
      opt=odeset('Jacobian',jac);
      [T,X]=ode23(vf,[t(1), 0, t(end%)],x0,opt);
    otherwise
      error('methor %s unknown.',method);
  end%switch
end%function
