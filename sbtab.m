## this is a set of functions that make it easier to work with sbtab files
1;

function [f]=find_file(folder,pattern)
  ##folder="../SBtab";
  assert(exist(folder));
  d=cellstr(ls(folder));
  m=regexp(d,pattern,"matches");
  i=cellfun(@isempty,m);
  pattern_files=cell2mat(m(not(i)));  
  file=strcat(folder,pattern_files{1});
  assert(exist(file));
  f=file;
endfunction

function [n,m]=layout(N)
  ##
  ## Usage: [n,m]=layout(N)
  ##   divides N subplots into an n×m layout,
  ##   where n*m=N
  f=factor(N);
  lf=length(f);
  nf=floor(lf/2);
  mf=lf-nf;
  [n,m]=deal(prod(f(1:nf)),prod(f(nf+1:lf)));  
endfunction

function [names,x0]=get_ode_model_names(vf_file)
  assert(exist(vf_file,"file"));
  f=fileread(vf_file);
  vf=strsplit(f,"\n");
  NM=regexp(vf,"^\\s*<StateVariable Name=\"(?<name>[^\"]+)\".*DefaultInitialCondition=\"(?<InitialCondition>[^\"]+)\"","names");

  names=cellfun(@(c) c.name,NM,"UniformOutput",false);
  i=cellfun(@isempty,names);
  names=names(not(i));
  ## these are the initial conditions that make it into the model
  ## file, excluding the ones that were turned into Mass Conservation
  ## Expressions
  x0=cellfun(@(c) str2double(c.InitialCondition),NM(not(i)));
endfunction

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
    ##[max_state,max_t]=max(state_t);
    ##max_t=merge(max_t==1,nt,max_t);
    Legend=names(sub_j);
    max_state=state_t(nt,:);
    max_t=ones(1,length(Legend))*nt;
    plot(t,state_t,"-;;");
    if not(isempty(names))
      text(t(max_t),max_state,Legend,"horizontalalignment","left","verticalalignment","middle");
    endif
    xlabel("t");
    xlim([-5 max(t)*1.3]);
    ylabel("state variables");
  endfor
endfunction

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
      printf("Compound %s from SBtab file was not found in reference simulation struct.\n",sbtab_name);
      ##assert(not(isempty(k)));
      k=j;
      ref_name="could not find in «reference»";
    else
      ref_name=names{2}{k};
    endif
    Label={sbtab_name,ref_name};
    l=[j,k];
    for i=1:2
      subplot(1,2,i);
      plot(t{i},X{i}(:,l(i)),"-;;");
      xlabel("t in s");
      ylabel(sprintf("[%s] in nM",Label{i}));
      if (nargin>=4)
	title(sprintf("%s simulation",varargin{i}));
      endif
    endfor
    a=axis();
    subplot(1,2,1);
    axis(a);
  endfor
endfunction

function show_state_variables(ivp,ref,state_vars,compounds)
  if not(exist("kmeans"))
    pkg load statistics
  endif

  nE=length(ivp);
  assert(nE==length(ref));
  for i=1:nE
    n_cX=columns(ivp(i).X);
    n_sv=length(state_vars);
    
    Label=genvarname(ivp(i).tag);
    trajectory_hash=ivp(i).hash;
    if not(exist(Label,"dir"))
      system(sprintf("mkdir './%s'",Label));
    endif
    
    X=ivp(i).X;
    t=ivp(i).t;
    if (columns(X)!=length(state_vars))
      printf("columns(X): %i, whereas length(state_vars): %i\n",columns(X),length(state_vars));
    endif
    printf("state var names:"); printf(" «%s»",state_vars{:}); printf("\n");
    f=cell(3,1);
    f{1}=plot_trajectories(t,X,state_vars);
    if isstruct(ref)
      f{2}=plot_trajectories(ref(i).t,ref(i).species,ref(i).species_name);
      f{3}=plot_pairwise_comparison({t,ref(i).t},{X,ref(i).species},{state_vars,ref(i).species_name},"vfgen/GNU Octave","Simbiology/Matlab");
    endif
    for k=1:2
      figure(f{k});
      set(gcf,"paperunits","centimeters");
      set(gcf,"papersize",PS=4*[30,20]);
      set(gcf,"paperposition",[0,0,PS]);
      out_file_name=sprintf("./%s/MGluR_print_Simulation_%s_%s_hash_%s.png",Label,merge(k==1,"octave_vfgen","reference"),Label,trajectory_hash);
      conditionally_print(f{k},out_file_name);
    endfor

    for j=1:n_cX
      cf=f{3}(j);
      figure(cf);
      set(gcf,"paperunits","centimeters");
      set(gcf,"papersize",PS=[20,10]);
      set(gcf,"paperposition",[0,0,PS]);
      out_file_name=sprintf("./%s/MGluR_Compound_%i_of_%i_%s_hash_%s.png",Label,j,n_cX,state_vars{j},trajectory_hash);
      conditionally_print(cf,out_file_name);
    endfor
  endfor
  pkg unload statistics
endfunction

function conditionally_print(fh,out_file_name)
  figure(fh);
  if exist(out_file_name,"file")
    printf("%s already exists, skipping.\n",out_file_name);
  else
    print("-dpng",out_file_name);
  endif
  close(fh);
endfunction

function [Output,out,out_name]=get_outputs(Output)
  assert(strcmp(Output.TableName,"Output"));
  j=strmatch("!Name",Output.raw(2,:),"exact");
  out_name=Output.raw(3:end,j(1));
  N=length(out_name);
  out_f_name=cell(N,1);
  l=cellfun(@ischar,Output.raw(1,:));
  Header1=strcat(Output.raw{1,l});
  printf("[get_outputs] SBtab Header: «%s»\n",Header1);
  NM = regexp(Header1,"Document='(?<ModelName>[^']+)'","names");
  for i=1:N
    display(NM.ModelName);
    out_f_name{i}=strcat(NM.ModelName,"_",out_name{i});
    display(out_f_name{i});
    if exist(out_f_name{i})
      printf("[get_outputs] output function «%s» is in the load path.\n",out_f_name{i});
    else
      warning("[get_outputs] output function «%s» is *not* in the load path.\n",out_f_name{i});
    endif
    out=@(t,x,p) cellfun(@feval,out_f_name,{t},{x},{p},"UniformOutput",true);
  endfor
endfunction

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
	warning("nan detected");
	display(y);
      endif
      ivp(j).Y=Y;
    endfor
  endfor  
endfunction

function show_outputs(ivp,Ref,E,out_name)
  ##[n,m]=layout(ny);
  nE=length(ivp);
  assert(nE==length(Ref));
  for i=1:nE
    for j=1:ny
      figure((i-1)*ny+j); clf();
      plot(t=ivp(i).t,Z=ivp(i).Z(:,j),";VFGEN/GNU Octave;","linewidth",1.5); hold on;
      xlim([-2,max(t)]);
      if any(j==E(i).MeasuredOutput)
	o=E(i).MeasuredOutput;
	plot(Ref(i).t,Ref(i).output,":;Simbiology/Matlab;","linewidth",2.5);      
	e1=errorbar(E(i).time,E(i).data(:,o),E(i).stdv(:,o),"~");
	set(e1,"linestyle","none");
      endif
      cn=strrep(out_name{j},"_mon","");
      c=strcmp(cn,Ref(i).species_name);
      if any(c)
	plot(Ref(i).t,Ref(i).species(:,c),"-;Simbiology/Matlab;");
      endif
      hold off;
      xlabel("t");
      ylabel(out_name{j});
      out_file_name=sprintf("./%s/MGluR_OutputFunction_%i_%s_hash_%s.png",ivp(i).tag,j,out_name{j},ivp(i).trajectory_hash);
      ##set(gca,"position",[0.08,0.1,0.87,0.87]);
      set(gca,"fontname","Fira Sans Book");
      set(gca,"fontsize",11);
      set(gcf,"paperunits","pixels");
      set(gcf,"papersize",PS=[1600,1200]);
      set(gcf,"paperposition",[0,0,PS]);
      set(gcf,"paperorientation","landscape");
      conditionally_print(gcf,out_file_name);
      close(gcf);
    endfor
  endfor
endfunction

function j=find_column(ColumnName,SBtab)
  if not(ischar(ColumnName))
    error("[find_column] not a string: «%s»",ColumnName);
  else
    printf("[find column] searching for «%s»\n",ColumnName);
  endif
  SBtabColumnNames=SBtab.raw(2,:);
  if not(iscellstr(SBtabColumnNames))
    warning("[find_column] weird «SBtab» argument:");
    j=cellfun(@ischar,SBtabColumnNames);
    Header=SBtabColumnNames(j);
  else
    Header=SBtabColumnNames;
  endif
  m=strmatch(ColumnName,Header,"exact");
  if (length(m)==1)
    j=m;
  elseif (length(m)>1)
    warning("more than one column matches this label.");
    printf(" «%s»",Header{m});
    j=m(1);
    printf("\nI will choose the first match: %s.\n",Header{j})
  else
    warning("Column «%s» not found.",ColumnName);
    j=[];    
  endif   
endfunction

function c=get_column(ColumnName,SBtab)
  j=find_column(ColumnName,SBtab);
  if not(isempty(j))
    c=SBtab.raw(3:end,j);
  endif
endfunction

function [c]=get_num_column(I,SBtab)
  ## Usage: [c]=get_num_column(i,SBtab), where i is the raw column
  ## number and SBtab is the table that contains a numerical part.
  L=SBtab.limits;
  n=L.numlimits;
  printf("[get_num_column] fetching column %i.\n",I);
  assert(any(isfinite(I)) && any(I>0));
  if (min(I)>=n(1,1) && max(I)<=n(1,2))
    J=1+I-n(1);
    f=isfinite(J);
    c=SBtab.num(1:end,J(f));
  else
    printf("Column %i:\n",i);
    printf("«%s»\n",SBtab.raw{2:end,i});    
    error("... not numerical",i);
  endif
endfunction

function [Experiment,Norm]=get_experimental_data(Experiments,Output,ods_file_name,InputDefaultsOfE,uID)
  assert(strcmp(Experiments.TableName,"Experiments"));
  assert(strcmp(Output.TableName,"Output"));
  yID=get_column("!ID",Output);  
  ErrorName=get_column("!ErrorName",Output);
  NormalisedByOutput=get_column("!RelativeTo",Output);
  if not(isempty(NormalisedByOutput))
    printf("Output Normalisation:\n");printf("«%s»",NormalisedByOutput{:});
  else
    printf("Outputs are absolute measurements.\n");
  endif
  ny=length(yID);
  printf("There are %i Output IDs.\n",ny);
  eID=get_column("!ID",Experiments);
  eName=get_column("!Name",Experiments);
  NE=length(eID);
  ##default time
  j=find_column("!Time",Experiments);
  DefaultTime=get_num_column(j,Experiments);
  
  eType=get_column("!Type",Experiments);
  ## [is_dose_response,is_time_series]=deal(NA(NE,1));  
  is_dose_response=not(isempty(regexpi(eType,"dose response",'start'){1}));
  is_time_series=not(isempty(regexpi(eType,"time series",'start'){1}));
  
  NormE=NA(NE,1);
  NormT=NA(NE,1)
  NormalisedByExperiment=get_column("!RelativeTo",Experiments);
  ##  l=cellfun(@isempty,NormalisedByExperiment);
  ##  [Norm{l}]=deal("");
  ## normalisation, by output
  if isempty(NormalisedByOutput)
    NormOut=1:ny;
  else
    NormOut=NA(ny,1);
    for i=1:ny
      nid=find(strcmp(NormalisedByOutput{i},yID),1);
      NormOut(i)=merge(not(isempty(nid)),nid,NA);
    endfor
  endif
  display(NormOut);
  ##normalisation, by experiment and time
  if isempty(NormalisedByExperiment)
    NormET=[];
  else
    display(NormalisedByExperiment);
    Match=regexp(NormalisedByExperiment,"(?<Experiment>\\w+)(\\[(?<TimePoint>\\w+)\\])?","names");
    NormE=cellfun(@(c) merge(isempty(f=find(strcmp(merge(isempty(c.Experiment),"",c.Experiment),eID),1)),NA,f),Match);
  endif
  display(NormE);
  display(NormT);  
  TP=cell(NE,1);
  E=get_sheets(ods_file_name,eID,eName);
  for i=1:NE
    data_I=NA(1,ny);
    stdv_I=NA(1,ny);
    ##E(i)=get_table(eID{i},ods_file_name);
    assert(isfield(E,"raw"));
    TP{i}=get_column("!TimePoint",E(i));
    for j=1:ny
      y_ref=strcat(">",yID{j});
      ##printf("looking up: «%s»\n",y_ref);
      l=find_column(y_ref,E(i));
      N=length(l);
      if isempty(l)
	data_I(j)=NA;	
      else
	data_I(j)=l;
      endif
      l=find_column(ErrorName{j},E(i));
      stdv_I(j)=merge(isempty(l),NA,l); ## same for standard deviations
    endfor
    data_k=find(not(isna(data_I))); ## which outputs were measured at all?
    stdv_k=find(not(isna(stdv_I)));
    ##
    clear j;
    if is_time_series(i)
      j=find_column("!Time",E(i));
      printf("[get_experimental_data] %s: «!Time» is column %i.\n",eID{i},j);
      t=get_num_column(j,E(i));
      nt=length(t);
      Experiment(i).time=t;
    elseif is_dose_response(i)
      ud=InputDefaultsOfE(i,:);
      nu=length(ud);
      assert(nu==length(uID));
      u=repmat(ud,[N,1]);
      for k=1:nu
	u_ref=strcat(">",Input.ID(i));
	j=find_column(u_ref,E(i));
	printf("[get_experimental_data] %s: «%s» is column %i.\n",eID{i},uID{i},j);
	if not(isempty(j))
	  u(:,k)=get_num_column(j,E(i));
	endif	  
      endfor

      Experiment(i).input=u;
      Experiment(i).time=DefaultTime(i);
    else
      error("unknown experiment type «%s»",eType{i});
    endif
    ##
    Values=NA(nt,ny);
    StandardDeviations=NA(nt,ny);
    Values(:,data_k)=get_num_column(data_I,E(i));
    StandardDeviations(:,stdv_k)=get_num_column(stdv_I,E(i));
    ##
    Experiment(i).MeasuredOutput=data_k;
    Experiment(i).data=Values;
    Experiment(i).stdv=StandardDeviations;
    Experiment(i).type=eType{i};
  endfor
  l=not(isna(NormE));
  NormT(l)=cellfun(@(m,j) merge(isempty(f=find(strcmp(m.TimePoint,TP{j}),1)),NA,f),Match(l),num2cell(NormE(l)));
  if not(isempty(NormE))
    for i=1:NE
      printf("plotting data for experiment «%s»\n",eID{i});
      if isna(NormT(i))
	T=1:length(Experiment(i).time);
      else
	T=NormT(i);
      endif
      if not(isna(j=NormE(i)))
	Experiment(i).data=bsxfun(@rdivide,Experiment(i).data,Experiment(j).data(T,:));
	Experiment(i).stdv=bsxfun(@rdivide,Experiment(i).stdv,Experiment(j).data(T,:)); ## this is slightly wrong, but a good approsimation and easy to write	
      endif
      figure(i); clf;
      k=Experiment(i).MeasuredOutput;
      printf("Measured Outputs:"); printf(" «%s»",yID{k}); printf("\n");
      subplot(1,2,1); cla;
      plot(Experiment(i).data,";;");
      subplot(1,2,2); cla;
      display(size(Experiment(i).time));
      display(size(Experiment(i).data(:,k)));
      display(size(Experiment(i).stdv(:,k)));
      nk=length(k);
      eh=errorbar(Experiment(i).time*ones(1,nk),Experiment(i).data(:,k),Experiment(i).stdv(:,k),"~+");
      set(eh,"linestyle","none");
      title(eID{i});
      xlabel("time");
      ylabel(sprintf("%s ",yID{k}));
    endfor
  endif
  Norm.T=NormT;
  Norm.E=NormE;
  Norm.O=NormOut;
endfunction

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
	endif
	T=1:nt; ## do it point by point
      else
	nt=1;
	T=Norm.T(i); ## normalisation time point
      endif
      if not(isna(j=Norm.E(i)))
	if (rows(ivp(i).Y)!=rows(ivp(j).Y))
	  T=T(end); ## override previous choice if there is a length mismatch
	endif
	ivp(i).Z=ivp(i).Y;
	ivp(i).Z(o)=bsxfun(@rdivide,ivp(i).Y(o),eps+ivp(j).Y(T,o));
      endif
    endfor
  endif
endfunction

function [name,x0]=get_compound_names(Compound)
  assert(strcmp(Compound.TableName,"Compound"));
  c=strmatch("!Name",Compound.raw(2,:),"exact");
  name=Compound.raw(3:end,c(1));

  printf("Model's Compound Names:");
  printf(" «%s»",name{:});
  printf("\n");
  i=find_column("!InitialValue",Compound);
  x0=get_num_column(i,Compound);  
endfunction

function [k]=get_default_parameters(Parameter);
  assert(strcmp(Parameter.TableName,"Parameter"))
  k=Parameter.num(:,1); 
endfunction

function [u,ID]=get_input(Input,Experiments)
  assert(strcmp(Input.TableName,"Input"));
  assert(strcmp(Experiments.TableName,"Experiments") || strcmp(Experiments.TableName,"TableOfExperiments"))
  j=find_column("!DefaultValue",Input);
  DefaultInput=get_num_column(j,Input);
  InputID=get_column("!ID",Input);
  nu=length(InputID);
  ID=get_column("!ID",Experiments);
  nE=length(ID);  
  UI=NA(1,nu);
  for i=1:nu
    c=find_column(strcat(">",InputID{i}),Experiments);
    UI(i)=c;
  endfor
  NumLimits=Experiments.limits.numlimits(1,:);
  UI-=NumLimits(1); # this is an offset
  UI+=1;            # this is an index
  f=isfinite(UI);
  u=ones(nE,1)*DefaultInput';
  for i=1:nE
    u(i,f)=Experiments.num(i,UI(f));
  endfor
endfunction

function [X,T]=forward_simulation(vf,jac,x0,t,varargin)
  method="default";
  if (nargin>4)
    method=varargin{1};
  endif
  if (nargin>5)
    T_CRIT=varargin{2};
  endif
  switch(method)
    case {"lsode","default"}
      lsode_options("integration method","bdf");
      lsode_options("absolute tolerance",1e-6);
      lsode_options("relative tolerance",1e-6);
      X=lsode({vf,jac},x0,t,T_CRIT);
      T=t;
    case {"ode45"}
      opt=odeset("Jacobian",jac);
      [T,X]=ode45(vf,[t(1), 0, t(end)],x0,opt);
    case {"ode23"}
      opt=odeset("Jacobian",jac);
      [T,X]=ode23(vf,[t(1), 0, t(end)],x0,opt);
    otherwise
      error("methor %s unknown.",method);
  endswitch
endfunction

function [table]=find_table(table_name,sbtab_file_name,sh_names)
  N=rows(sh_names);
  i=0;
  do
    clear Match table
    [table.num, table.txt, table.raw, table.limits] = odsread(sbtab_file_name,++i,"","OCT");
    c=cellfun(@ischar,table.raw(1,:));
##    display(table.raw(1,c));
    NM = regexp(cstrcat(table.raw{1,c}), "TableName\\s*=\\s*'(?<TableName>[^']+)'","names");
    TableName=NM.TableName;
    printf("TableName=«%s»\n",TableName);
    successful_match=logical(strcmp(table_name,TableName));
    printf("«%s»==«%s»? %s\n",table_name,TableName,merge(successful_match,"true","false"));
    table.name=TableName;
  until (successful_match || i>=N);
  if not(successful_match)
    warning("Did not find table «%s» in file «%s».\n Sheets:",table_name,sbtab_file_name);
    printf(" «%s»",sh_names{:,1});
    printf("\n");
    table=[];
  else
    printf("[find_table] Success.\n");
  endif
endfunction

function [table]=get_table(name,sbtab_file_name)
  [filetype, sh_names] = odsfinfo(sbtab_file_name);
  printf("file type: «%s» with the sheets: ",filetype);
  printf(" «%s»",sh_names{:,1});
  printf("\n");
  if iscell(name)
    printf("searching for:");
    printf("\t«%s»\n",name{:});
  endif
  N=rows(sh_names);
  if ischar(name)
    printf("searching for: «%s».\n",name);
    i=strmatch(name,sh_names,"exact");
##    if isempty(i)
##      i=strmatch(name,sh_names);
##    endif
  elseif iscellstr(name)
    j=0;
    do
      i=strmatch(name{++j},sh_names,"exact");
    until (not(isempty(i))||j>=N)
  endif
  if (not(isempty(i)))
    [table.num, table.txt, table.raw, table.limits] = odsread(sbtab_file_name,round(i(1)),"","OCT");
  else
    warning("«%s» is not a sheet name.",name);
    table=find_table(name,sbtab_file_name,sh_names);
  endif
  assert(isstruct(table));
endfunction

function [table]=get_sheets(ods_file,IDs,varargin)
  if nargin>2
    names=varargin{1};
  else
    names=IDs;
  endif
  if iscell(names)
    N=length(names)
  else
    N=1;
  endif
  for i=1:N
    table(i).sheet_name=names{i};    
    try
      [table(i).num, table(i).txt, table(i).raw, table(i).limits] = odsread(ods_file,names{i});
    catch
      warning("Table «%s» not found (a sheet name in the ods file).\n",names{i});
      try
	[table(i).num, table(i).txt, table(i).raw, table(i).limits] = odsread(ods_file,IDs{i});
      end
    end
    c=cellfun(@ischar,table(i).raw(1,:));
    NM = regexp(cstrcat(table(i).raw{1,c}), "TableName\\s*=\\s*'(?<TableName>[^']+)'","names");
    TableName=NM.TableName;
    printf("TableName=«%s»\n",TableName);
    table(i).TableName=TableName;
  endfor
endfunction
