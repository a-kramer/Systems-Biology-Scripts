#!/usr/bin/octave-cli
function M=copasi_C_vfgen(file,varargin)
  ## Usage:...
  ##
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
  name=get_NAME_ARRAYS(line(I{3}));
  ic=get_INITIAL(line(I{4}));
  Fixed=get_FIXED(line(I{5}));
  A=get_ASSIGNMENT(line(I{6}),name);
  Flux=get_FUNCTIONS(line(I{8}))
  ODE=get_ODEs(line(I{9}),name,Flux);
  
  fid=fopen(sprintf("%s.xml",ModelName),'w');
  fprintf(fid,'<?xml version="1.0" ?>');
  fprintf(fid,"<VectorField\n\tName=\"%s\"\n\tDescription=\"%s\">",ModelName,ModelDescription);
  write_Constants(fid,name,Fixed);
  write_Parameters(fid,name,Fixed);
  write_Expressions(fid,name,A,Flux);
##  write_Functions(fid,name,Flux);
  write_StateVariables(fid,name,ODE);
  fprintf(fid,"</VectorField>");
  fclose(fid);
endfunction


## the following get_ functions will read in the lines of a given file and do some basic
## preprocessing, strip spaces, convert C-brackets to octave
## parentheses for vector indeces:

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
  FixedValues.p=p
  FixedValues.ct=ct;
endfunction

function A=get_ASSIGNMENT(line,name)
  ## this function
  N=length(line);
  A=cell(N,1);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'(\w+)\[(\d+)\] = (.*);\s*#.*''(\w+)'':.*','{"$4","$3",$2,"$1"}');
##    printf("eval «%s»\n",line{i});
    L=eval(line{i});
    ## replace all parameter names
    for j=1:length(name.p)
      pattern=regexptranslate('escape',sprintf("p[%i]",j-1));
      L{2}=regexprep(L{2},pattern,name.p{j});
    endfor
    ## replace all metabolite names
    for j=1:length(name.x)
      pattern=regexptranslate('escape',sprintf("x[%i]",j-1));
      L{2}=regexprep(L{2},pattern,name.x{j});
    endfor
    for j=1:length(name.y)
      pattern=regexptranslate('escape',sprintf("y[%i]",j-1));
      L{2}=regexprep(L{2},pattern,name.y{j});
    endfor
    for j=1:length(name.ct)
      pattern=regexptranslate('escape',sprintf("ct[%i]",j-1));
      L{2}=regexprep(L{2},pattern,name.ct{j});
    endfor
    A{i}=L;
  endfor
endfunction

function Flux=get_FUNCTIONS(line)
  ## fluxes
  ##
  
  N=length(line)
  Flux=cell(N,1);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'(\w+) = (.*);\s*#.*''(.+)'':.*','{"$1","$2","$3"}');
    ##printf("eval «%s»\n",line{i});
    L=eval(line{i});
    Flux{i}=L;
  endfor
endfunction

function ODE=get_ODEs(line,name,Flux)
  N=length(line);
  for i=1:N
    line{i}=regexprep(line{i},'//','#');
    line{i}=regexprep(line{i},'\s','');
    line{i}=regexprep(line{i},'(\w+)\[(\d+)\]=(.*);#.*','{"$1",$2,"$3"}');
    ##printf("eval: «%s»\n",line{i});
    L=eval(line{i});
    for j=1:length(Flux)
     ## printf("«%s» → «%s»\n",Flux{j}{2},Flux{j}{1});
      L{3}=regexprep(L{3},regexptranslate('escape',Flux{j}{2}),Flux{j}{1});
    endfor
    ODE{i}=L;
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
  ## name is a struct with names of
  ## name.p: parameters
  ## name.x: state variables
  ## name.y: conserved metabolites
  ## name.ct: name of conserved total of some metabolites
  Tag="<Expression Name=\"%s\" Description=\"%s\" Formula=\"%s\"/>\n";
  for i=1:length(A)
    if strcmp(A{i}{4},'y')
      Description="conserved quantity";
    else
      Description="mol to M";
    endif
    fprintf(fid,Tag,A{i}{1},Description,A{i}{2});
  endfor
  for i=1:length(Fluxes)
    ## replace all state variables in flux
    flux=Fluxes{i}{2};
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
    fprintf(fid,Tag,Fluxes{i}{1},Fluxes{i}{3},flux);
  endfor
endfunction


function write_StateVariables(fid,name,ODE)
  ## name is a struct with names of
  ## name.p: parameters
  ## name.x: state variables
  ## name.y: conserved metabolites
  ## name.ct: name of conserved total of some metabolites
  Tag="<StateVariable Name=\"%s\" Description=\"%s\" Formula=\"%s\"/>\n";
  for i=1:length(ODE)
    printf("ODE[%i] ",i);
    Description=sprintf("state variable %i",i);
    xdot=regexprep(ODE{i}{3},'p\[0\]',name.p{1});
    printf("%s\n",xdot);
    fprintf(fid,Tag,name.xc{i},Description,xdot);
  endfor
endfunction



