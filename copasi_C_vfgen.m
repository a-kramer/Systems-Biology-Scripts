#!/usr/bin/octave-cli
function copasi_C_vfgen(file,varargin)
  ## Usage: copasi_C_vfgen(file,ModelName,ModelDescription)
  ##
  ## converts a model (text file) from copasi's C export function to octave and vfgen
  ## ModelName will be used for naming the created functions (Default: SBModel)
  ## ModelDescription is optional
  ModelName="SBModel";
  ModelDescription="copasi_C_vfgen(file,ModelName,→ModelDescription)";
  if length(varargin)>0
    ModelName=varargin{1};    
  endif
  if length(varargin)>1
    ModelDescription=varargin{2};
  endif
  if exist(file,'file')
    fid=fopen(file,'r');
  else
    error("file does not exist: %s\n",file);
  endif
  ## read the whole file into a cell array
  line={};
  i=1;
  while ( ischar(l=fgetl(fid)) || isempty(l) )
     line{i++}=l;
  endwhile
  N=length(line)
  fclose(fid);
  ## find the various sections of the file:
  SectionTitle={"SIZE_DEFINITIONS";
		 "TIME";
		 "NAME_ARRAYS";
		 "INITIAL";
		 "FIXED";
		 "ASSIGNMENT";
		 "FUNCTIONS_HEADERS";
		 "FUNCTIONS";
		 "ODEs"};

  n_sec=length(SectionTitle);
  I=cell(n_sec,1); # a logical array, marking sections in the C file
  for i=1:n_sec
    c=regexp(line,cat(2,'#ifdef ',SectionTitle{i},"$")); # Title at end of line
    I{i}=!cellfun(@isempty,c);
    i_start=min(find(I{i}));
    c=strfind(line,'#endif');
    J=find(!cellfun(@isempty,c));
    i_end=min(J(J>i_start));
    I{i}(i_start:i_end)=true;
    I{i}(i_start)=false; # let's exclude the actual block markers
    I{i}(i_end)=false;   # 
  endfor
  ##I
  S=get_SIZE_DEFINITIONS(line(I{1}));
  name=get_NAME_ARRAYS(line(I{3}));
  ic=get_INITIAL(line(I{4}));
  Fixed=get_FIXED(line(I{5}));
  A=get_ASSIGNMENT(line(I{6}),name);
  Flux=get_FUNCTIONS(line(I{8}),S);
  ODE=get_ODEs(line(I{9}),name);
  NewFlux=crossreference_Fluxes_with_ODEs(ODE,Flux,name);
  fid=fopen(sprintf("%s.xml",ModelName),'w');
  fprintf(fid,'<?xml version="1.0" ?>');
  fprintf(fid,"<VectorField\n\tName=\"%s\"\n\tDescription=\"%s\">\n",ModelName,ModelDescription);
  write_Constants(fid,name,Fixed);
  write_Parameters(fid,name,Fixed);
  vfgen_fluxes=replace_vars_in_fluxes(NewFlux,name);
  write_Expressions(fid,name,A,vfgen_fluxes);
##  write_Functions(fid,name,Flux);
  write_StateVariables(fid,name,ODE,vfgen_fluxes);
  fprintf(fid,"</VectorField>");
  fclose(fid);
## write some GNU Octave files directly
  Model.Name=ModelName;
  Model.size=S;
  Model.Description=ModelDescription;
  Model.ic=ic;
  Model.Assign=A;
  Model.Fixed=Fixed;
  Model.Flux=NewFlux;
  Model.ODE=ODE;
  Model.identifiers=name;
  make_Octave_model(Model);
endfunction

function make_Octave_model(Model)
  if (isfield(Model,'Name') && length(Model.Name)!=0)
    f_file=sprintf("%s.m",Model.Name);
  else
    error('Model Name undefined.');
  endif
  fid=fopen(f_file,'w');
  fprintf(fid,"# %s\n# %s\n",Model.Name,Model.Description);
  fprintf(fid,"if (exist(\"%s\",'var'))\n\terror('Model %s already exists.');\nendif\n\n",Model.Name,Model.Name);
  fprintf(fid,"%s.id.x={",Model.Name);
  for i=1:Model.size.x
    fprintf(fid," \"%s\" ",Model.identifiers.x{i});
  endfor
  fprintf(fid,"};\n");
  fprintf(fid,"%s.id.p={",Model.Name);
  for i=1:Model.size.p
    fprintf(fid," \"%s\" ",Model.identifiers.p{i});
  endfor
  fprintf(fid,"};\n");
  fprintf(fid,"%s.id.ct={",Model.Name);
  for i=1:Model.size.ct
    fprintf(fid," \"%s\" ",Model.identifiers.ct{i});
  endfor
  fprintf(fid,"};\n");
  fprintf(fid,"%s.id.y={",Model.Name);
  for i=1:Model.size.y
    fprintf(fid," \"%s\" ",Model.identifiers.y{i});
  endfor
  fprintf(fid,"};\n");
  fprintf(fid,"%s.DefaultParameters=[",Model.Name);
  for i=1:length(Model.Fixed.p)
    fprintf(fid," %g; ",Model.Fixed.p(i));
  endfor
  fprintf(fid,"];\n");
  fprintf(fid,"%s.InitialConditions=[",Model.Name);
  for i=1:Model.size.x
    fprintf(fid," %g; ",Model.ic(i));
  endfor
  fprintf(fid,"];\n");
  fprintf(fid,"%s.ConservedTotals=[",Model.Name);
  for i=1:Model.size.ct
    fprintf(fid," %g; ",Model.Fixed.ct(i));
  endfor
  fprintf(fid,"];\n");
  
  
  fprintf(fid,"%s.nx=%i;\n",Model.Name,Model.size.x);
  fprintf(fid,"%s.ny=%i;\n",Model.Name,Model.size.y);
  fprintf(fid,"%s.nr=%i;\n",Model.Name,length(Model.Flux));
  fprintf(fid,"%s.np=%i;\n\n",Model.Name,Model.size.p);
  fprintf(fid,"p=rand(%i,1);# this is an example for parametrisation\n",length(Model.identifiers.p))
  fprintf(fid,"%s.f=@(x,t) %s_f(%s_flux(x,t,p));\n",Model.Name,Model.Name,Model.Name);
  fprintf(fid,"function ReactionFlux=%s_flux(x_c,t,p)\n## Usage: %s_flux(x_c,t,p);\n##This function calculates the fluxes of the Model given concentrations x_c, time t and parameters p.\n",Model.Name,Model.Name);
  for i=1:length(Model.Fixed.ct)
    fprintf(fid,"ct(%i)=%g; # %s\n",i,Model.Fixed.ct(i),Model.identifiers.ct{i});
  endfor
  ##  A=struct("id",num2cell([1:N]),"annotation",[],"expression",[],"index",[],"name",[]);
  ##{Model.Assign.name}
  i_y=strcmp({Model.Assign.annotation},'y');
  assign={Model.Assign.raw}(i_y);
  [m_s, m_e, token_extent, match_text, token, ~, token_complement] = regexp(assign,'\[(\d+)\]');
  for i=1:length(token)
    ie=cellfun(@str2num,cat(2,token{i}{:}))+1; # to compensate for C indexing starting at 0
    reindexed_assignment=token_complement{i}{1};
    for j=1:length(ie)
      reindexed_assignment=cat(2,reindexed_assignment,sprintf("(%i)%s",ie(j),token_complement{i}{j+1}));
    endfor
    fprintf(fid,"y_c(%i)=%s; # %s\n",i,reindexed_assignment,Model.Assign(i).name);
  endfor
  for i=1:length(Model.Flux)
    flux=Model.Flux(i).value;
    [m_s, m_e, token_extent, match_text, token, ~, token_complement] = regexp(flux,'\[(\d+)\]');
    ie=cellfun(@str2num,cat(2,token{:}))+1; # to compensate for C indexing starting at 0
    reindexed_flux=token_complement{1};
    for j=1:length(ie)
      reindexed_flux=cat(2,reindexed_flux,sprintf("(%i)%s",ie(j),token_complement{j+1}));
    endfor
    fprintf(fid,"ReactionFlux(%i)=%s; # %s: %s\n",i,reindexed_flux,Model.Flux(i).name,Model.Flux(i).reaction);
  endfor
  fprintf(fid,"endfunction\n\n");
  fprintf(fid,"function xdot=%s_f(flux,p)\n## Usage: %s_f(flux,p)\n## This function calculates the Ordinary Differential Equation System's right-hand-side.\n",Model.Name,Model.Name);
  fprintf(fid,"## if your ordinary differential equation model's right-hand-side has y_c or x_c terms\n## written out explicitely and not as a named flux, put x_c and y_c into thge argument list in the function definition (above) as well.\n");
  
  fprintf(fid,"xdot=zeros(%i,1);\n",length(Model.identifiers.x));
  for i=1:length(Model.ODE);
    ODE=Model.ODE(i).rhs;
    ##printf("ODE-rhs[%i]: «%s»\n",i,ODE);
    for j=1:length(Model.Flux)
      pattern=regexptranslate('escape',Model.Flux(j).raw);
      ##printf("replacing «%s»\n",pattern);
      ODE=regexprep(ODE,pattern,sprintf("ReactionFlux(%i)",j));
    endfor
    ##ODE=regexprep(ODE,"(\*p)?\\[0\\]",sprintf("p(1)")); # reindex the compartment parameter p[0] as p(1) as arrays start at 1 in Octave
    [m_s, m_e, token_extent, match_text, token, ~, token_complement] = regexp(ODE,'\[(\d+)\]');
    ie=cellfun(@str2num,cat(2,token{:}))+1; # to compensate for C indexing starting at 0
    reindexed_ODE=token_complement{1};
    for j=1:length(ie)
      reindexed_ODE=cat(2,reindexed_ODE,sprintf("(%i)%s",ie(j),token_complement{j+1}));
    endfor
    fprintf(fid,"xdot(%i)=%s; ## %s\n",i,reindexed_ODE,Model.identifiers.x{i});
  endfor
  fprintf(fid,"endfunction\n\n");
  fclose(fid);
endfunction


## the following get_ functions will read in the lines of a given file and do some basic
## preprocessing, strip spaces, convert C-brackets to octave
## parentheses for vector indeces:

function S=get_SIZE_DEFINITIONS(line)
##define N_METABS 35
##define N_ODE_METABS 0
##define N_INDEP_METABS 30
##define N_COMPARTMENTS 1
##define N_GLOBAL_PARAMS 0
##define N_KIN_PARAMS 67
##define N_REACTIONS 67
##define N_ARRAY_SIZE_P  43	// number of parameters
##define N_ARRAY_SIZE_X  19	// number of initials
##define N_ARRAY_SIZE_Y  2	// number of assigned elements
##define N_ARRAY_SIZE_XC 19	// number of x concentration
##define N_ARRAY_SIZE_PC 0	// number of p concentration
##define N_ARRAY_SIZE_YC 2	// number of y concentration
##define N_ARRAY_SIZE_DX 19	// number of ODEs 
##define N_ARRAY_SIZE_CT 2	// number of conserved totals
  N=length(line);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'#define','');
    line{i}=regexprep(line{i},'(\w+)\s+(\d+)','$1=$2;');
    #printf("evaluating «%s»\n",line{i});
    eval(line{i});
  endfor
  S.p=N_ARRAY_SIZE_P;
  S.x=N_ARRAY_SIZE_XC;
  S.y=N_ARRAY_SIZE_YC;
  S.ct=N_ARRAY_SIZE_CT;
  S.r=N_REACTIONS;
endfunction

function name=get_NAME_ARRAYS(line)
  N=length(line);
  for i=1:N
    line{i}=regexprep(line{i},'const\s*char\*\s*','');
    line{i}=regexprep(line{i},'\[\]','');
    #printf("evaluating «%s»\n",line{i});
    eval(line{i});
  endfor
  ##line
  name.p=regexprep(p_names,'\s','__');
  name.x=regexprep(x_names,'\s','__');
  name.y=regexprep(y_names,'\s','__');
  name.xc=regexprep(xc_names,'\s','__');
  name.yc=regexprep(yc_names,'\s','__');
  name.dx=regexprep(dx_names,'\s','__');
  name.ct=regexprep(ct_names,'\s','__');
  ## make p names unique
  for i=1:length(name.p)
    name.p{i}=cat(2,name.p{i},sprintf("__P%i",i));
  endfor
endfunction

function IC=get_INITIAL(line)
  N=length(line);
  for i=1:N
    line{i}=regexprep(line{i},'\[(\d+)\]','($1+1)');
    line{i}=regexprep(line{i},'//','#');
    ##printf("evaluating «%s»\n",line{i});
    eval(line{i});
  endfor
  IC=x;
endfunction

function FixedValues=get_FIXED(line)
  ## this gets all kinds of fixed values, inputs, internal parameters, constants
  N=length(line);
  for i=1:N
    line{i}=regexprep(line{i},'\[(\d+)\]','($1+1)');
    line{i}=regexprep(line{i},'//','#');
  ##  printf("evaluating «%s»\n",line{i});
    eval(line{i});
  endfor
  FixedValues.p=p;
  FixedValues.ct=ct;
endfunction

function A=get_ASSIGNMENT(line,name)
  ## this function
  N=length(line);
  A=struct("id",num2cell([1:N]),"annotation",[],"expression",[],"index",[],"name",[]);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'(\w+)\[(\d+)\] = (.*);\s*#.*''(\w+)'':.*','{"$1",$2+1,"$3","$4"}');
##    printf("eval «%s»\n",line{i});
    L=eval(line{i});
    L{5}=L{3};
    ## replace all parameter names
    for j=1:length(name.p)
      pattern=regexptranslate('escape',sprintf("p[%i]",j-1));
      L{3}=regexprep(L{3},pattern,name.p{j});
    endfor
    ## replace all metabolite names
    for j=1:length(name.x)
      pattern=regexptranslate('escape',sprintf("x[%i]",j-1));
      L{3}=regexprep(L{3},pattern,name.x{j});
    endfor
    for j=1:length(name.y)
      pattern=regexptranslate('escape',sprintf("y[%i]",j-1));
      L{3}=regexprep(L{3},pattern,name.y{j});
    endfor
    for j=1:length(name.ct)
      pattern=regexptranslate('escape',sprintf("ct[%i]",j-1));
      L{3}=regexprep(L{3},pattern,name.ct{j});
    endfor
    A(i).raw=L{5};
    A(i).annotation=L{1}; # conserved quantity or mol to M conversion: so, "y" or "x_c"
    A(i).index=L{2};
    A(i).expression=L{3};
    A(i).name=L{4};
  endfor
endfunction

function Flux=get_FUNCTIONS(line,S)
  ## fluxes
  ##
  N=length(line);
  nF=S.r;
  Flux=struct('id',num2cell([1:nF]),'type',[],'name',[],'args',[],'return',[],'value',[],'reaction',[]);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    if !isempty(regexp(line{i},'double\s+\w+\('))
      fheader=regexprep(line{i},'\s*double\s+(\w+)\((.*)\).*','{"$1","$2"');
      fbody=regexprep(line{i+1},'\s*{return\s+(.*);}\s*','"$1"}');
      ##printf("header: %s\nbody: %s\n",fheader,fbody);
      s=sprintf("%s,%s",fheader,fbody);
      L=eval(s);
      Flux(i).type="function";
      Flux(i).name=regexprep(L{1},'\s+','');
      Flux(i).args=regexprep(strsplit(L{2},{','}),'\s*double\s*',''); # formal arguments, without type
      Flux(i).return=regexprep(L{3},'\s+','');
      Flux(i).raw=sprintf("%s(%s)",L{1},L{2});
    elseif !isempty(regexp(line{i},'\w+ = .*;'))
      line{i}=regexprep(line{i},'(\w+) = (.*);\s*#.*''(.+)'':.*','{"$1","$2","$3"}');
      L=eval(line{i});
      Flux(i).type="expression";
      Flux(i).name=regexprep(L{1},'\s+','');
      Flux(i).raw=regexprep(L{2},'\s+',''); # this will be unchanged and used to find fluxes in the ode rhs
      Flux(i).value=regexprep(L{2},'\s+',''); # this will be changed later on and used as a vfgen Expression
      Flux(i).reaction=regexprep(L{3},'\s+','');
    endif
    ##printf("eval «%s»\n",line{i});
  endfor
endfunction

function ReturnFlux=crossreference_Fluxes_with_ODEs(ODE,Fluxes,name)
  ## This is a complicated case as the fluxes have to be cross
  ## referenced with the ODEs and each call of a flux function has
  ## to be evaluated with the given arguments at execution. The
  ## same fluxfunction could be called with two or more different
  ## argument sets, so we have to create exactly one expression
  ## for each different call (each argument set). This requires a
  ## bookkeeping structure to check whether a given call has been
  ## expressed already.
  Table=struct('key',"",'value',0);

  Ftypes={Fluxes.type};
  is_expression=strcmp(Ftypes,'expression');
  is_function=strcmp(Ftypes,'function');
  printf("Expression Fluxes: %i\nFunction Fluxes: %i\n",sum(is_expression),sum(!is_expression));
  NewFlux=struct("type",[],"name",[],"value",[],"reaction",[],"raw",[]);
  n=0; # number of new fluxes
  Flux=Fluxes(is_function);
  Flex=Fluxes(is_expression);
  Flex=rmfield(Flex,'return');
  Flex=rmfield(Flex,'args');
  Flex=rmfield(Flex,'id');  
  clear Fluxes;
  for i=1:sum(is_function)
    nargs=length(Flux(i).args);
    ##printf("dealing with flux: %s\n",Flux(i).name);
    if isempty(Flux(i).name)
	  error("Flux(i).name empty: %s",i,Flux(i).name);
    endif
    call_pattern=sprintf("%s\\(",Flux(i).name);
    for k=1:nargs
      call_pattern=cat(2,call_pattern,sprintf("[\\w\\[\\]]+%s",merge(k==nargs,"\\)",",")));
    endfor
    ## call_pattern
    for j=1:length(ODE)
      ode=ODE(j).rhs;
     ## printf('looking for «%s» in «%s»\n',call_pattern,ode);
      
      if !isempty(regexp(ode,call_pattern))
	call=sprintf(".*(%s)\\(([^\\)]+)\\).*",Flux(i).name);
	F=eval(regexprep(ode,call,'{"$1","$2"}'));
	a=strsplit(F{2},{',',' '});
	c=sprintf("%s(",F{1}); # signature
	##
	for k=1:nargs
	  c=cat(2,c,sprintf("%s%s",a{k},merge(k==nargs,')',',')));
	endfor
	##c
	T=strcmp({Table.key},c);
	if any(T)
	  Table(T).value++;
	else
	  new.key=c;
	  new.value=1;
	  Table=cat(2,Table,new);
	  ## This is the first time such a call was encountered, so put resulting flux expression into the return array
	  flux=Flux(i).return;
	  ##printf("found new flux: %s.\n",flux);
	  for k=1:nargs
	    flux=regexprep(flux,Flux(i).args{k},a{k});
	  endfor
	  fxname=sprintf("%s__",Flux(i).name);
	  for k=1:nargs
	    ##fxname=cat(2,fxname,sprintf("%s%s",regexprep(a{k},'\[(\d+)\]','$1'),merge(k==nargs,"","__")));
	    idx=eval(regexprep(a{k},'\w+\[(\d+)\]','$1+1')); # +1 to compensate C array indexing starting at 0
	    if !isempty(regexp(a{k},'x_c'))
	      A=name.xc{idx};
	    elseif !isempty(regexp(a{k},'y_c'))
	      A=name.yc{idx};
	    elseif !isempty(regexp(a{k},'p'))
	      A=name.p{idx};
	    else
	      A=regexprep(a{k},'\[(\d+)\]',num2str(idx));
	    endif
	      fxname=cat(2,fxname,sprintf("%s%s",A,merge(k==nargs,"","__")));	    
	  endfor
	  n++;
	  NewFlux(n).type="expression";
	  NewFlux(n).value=flux;
	  NewFlux(n).name=fxname;
	  NewFlux(n).reaction="Flux; custom function call";
	  NewFlux(n).raw=c;
	endif
      endif
    endfor
  endfor
  ##for i=1:length(Table)
  ##  printf("%s\t\t\t%i\n",Table(i).key,Table(i).value);
  ##endfor
  ##Flex
  ##NewFlux
  if (n>0)
    ##printf("%i function fluxes.\n",n);
    ReturnFlux=cat(2,Flex,NewFlux);
  else
    ReturnFlux=Flex;
  endif
  printf("number of new expression fluxes: %i\n",length(NewFlux));
endfunction

function ODE=get_ODEs(line,name)
  N=length(line);
  ODE=struct('id',num2cell([1:N]),'name',[],'rhs',[],'rhs_flux',[]);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'\s+','');
    line{i}=regexprep(line{i},'(\w+)\[(\d+)\]=(.*);#.*','{"$1",$2+1,"$3"}');
    ##printf("eval: «%s»\n",line{i});
    L=eval(line{i});
    ODE(i).name=L{1};
    ODE(i).index=L{2};
    ODE(i).rhs=L{3};
  endfor
endfunction


## the write functions will create a vfgen compatible file
function write_Constants(fid,name,Fixed)
  ## name is a struct with names of
  ## name.p: parameters
  ## name.x: state variables
  ## name.y: conserved metabolites
  ## name.ct: name of conserved total of some metabolites
  Tag="<Constant Name=\"%s\" Description=\"%s\" Value=\"%i\"/>\n";
  fprintf(fid,Tag,name.p{1},"Reaction Compartment",Fixed.p(1));
endfunction

function write_Parameters(fid,name,Fixed)
  ## name is a struct with names of
  ## name.p: parameters
  ## name.x: state variables
  ## name.y: conserved metabolites
  ## name.ct: name of conserved total of some metabolites
  Tag="<Parameter Name=\"%s\" Description=\"%s\" DefaultValue=\"%i\"/>\n";
  for i=2:length(Fixed.p)
    fprintf(fid,Tag,name.p{i},"uncertain parameter",Fixed.p(i));
  endfor
endfunction

function write_Expressions(fid,name,A,Fluxes)
  ## name is a struct with names of name.p: parameters name.x: state
  ## variables name.y: conserved metabolites name.ct: name of
  ## conserved total of some metabolites
  Tag="<Expression Name=\"%s\" Description=\"%s\" Formula=\"%s\"/>\n";
  for i=1:length(A)
    if strcmp(A(i).annotation,'y')
      Description="conserved quantity";
    else
      Description="mol to M";
    endif
    fprintf(fid,Tag,A(i).name,Description,A(i).expression);
  endfor
  for i=1:length(Fluxes)
    fprintf(fid,Tag,Fluxes(i).name,Fluxes(i).reaction,Fluxes(i).value);
  endfor
endfunction

function VFGEN_flux=replace_vars_in_fluxes(Fluxes,name)
  VFGEN_flux=Fluxes;
  for i=1:length(Fluxes)
    ## replace all state variables in flux
    flux=Fluxes(i).value;
    if isempty(flux)      
      error("flux(%i) empty: «%s»",i,flux);
    endif
    for j=1:length(name.xc)
      pattern=regexptranslate("escape",sprintf("x_c[%i]",j-1));
      flux=regexprep(flux,pattern,name.xc{j});
    endfor
    for j=1:length(name.yc)
      pattern=regexptranslate("escape",sprintf("y_c[%i]",j-1));
      flux=regexprep(flux,pattern,name.yc{j});
    endfor
    for j=1:length(name.p)
      pattern=regexptranslate("escape",sprintf("p[%i]",j-1));
      flux=regexprep(flux,pattern,name.p{j});
    endfor
    VFGEN_flux(i).value=flux;    
  endfor
endfunction


function write_StateVariables(fid,name,ODE,Flux)
  ## name is a struct with names of
  ## name.p: parameters
  ## name.x: state variables
  ## name.y: conserved metabolites
  ## name.ct: name of conserved total of some metabolites
  Tag="<StateVariable Name=\"%s\" Description=\"%s\" Formula=\"%s\"/>\n";
  ##printf("%i fluxes.\n",length(Flux));
  for i=1:length(ODE)
    ##printf("ODE[%i] ",i);
    Description=sprintf("state variable %i",i);
    xdot=regexprep(ODE(i).rhs,'(\*)?p\[0\](\*)?',""); # delete all compartment factors
    for j=1:length(Flux)
	fxname=Flux(i).name;
	if isempty(fxname)
	  error("flux name is empty");
	else
	  ##printf("«%s» → «%s»\n",Flux(j).raw,Flux(j).name);
	  fpat=regexptranslate('escape',Flux(j).raw);
	  xdot=regexprep(xdot,fpat,Flux(j).name);
	endif
    endfor
    ## also replace all variables and parameters even if they are not in a flux:
    ##printf("replace %i xc names, %i yc names, and %i p names.\n",length(name.xc),length(name.yc),length(name.p))
    for j=1:length(name.xc)
      pattern=regexptranslate("escape",sprintf("x_c[%i]",j-1));
      xdot=regexprep(xdot,pattern,name.xc{j});
    endfor
    for j=1:length(name.yc)
      pattern=regexptranslate("escape",sprintf("y_c[%i]",j-1));
      xdot=regexprep(xdot,pattern,name.yc{j});
    endfor
    for j=1:length(name.p)
      pattern=regexptranslate("escape",sprintf("p[%i]",j-1));
      xdot=regexprep(xdot,pattern,name.p{j});
    endfor    
    ##printf("%s\n",xdot);
    fprintf(fid,Tag,name.xc{i},Description,xdot);
  endfor
endfunction



