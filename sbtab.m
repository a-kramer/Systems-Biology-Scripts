## this is a set of functions that make it easier to work with sbtab files
printf("loading the functions: \n\
\t· function [f]=find_file(folder,pattern);\n\
\t· function [Output,out,out_name]=get_outputs(Output);\n\
\t· function j=find_column(ColumnName,SBtab);\n\
\t· function c=get_column(ColumnName,SBtab);\n\
\t· function [c]=get_num_column(I,SBtab);\n\
\t· function [Experiment,Norm]=get_experimental_data(Experiments,Output,ods_file_name,InputDefaultsOfE,uID);\n\
\t· function [name,x0]=get_compound_names(Compound);\n\
\t· function [k]=get_default_parameters(Parameter);\n\
\t· function [u,ID]=get_input(Input,Experiments);\n\
\t· function [table]=find_table(table_name,sbtab_file_name,sh_names);\n\
\t· function [table]=get_table(name,sbtab_file_name);\n\
\t· function [table]=get_sheets(ods_file,IDs,varargin).\n");

pkg load io

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

function [c]=get_num_column(Columns,SBtab)
  ## Usage: [c]=get_num_column(i,SBtab), where i is the raw column
  ## number and SBtab is the table that contains a numerical part.
  L=SBtab.limits;
  n=L.numlimits;
  assert(all(isfinite(Columns)) && all(Columns>0));
  nC=length(Columns);
  c=NA(rows(SBtab.num),nC);
  for i=1:nC
    I=Columns(i);
    printf("[get_num_column] fetching column %i.\n",I);
    if (I>=n(1,1) && I<=n(1,2))
      J=1+I-n(1);
      f=isfinite(J);
      c(:,i)=SBtab.num(1:end,J(f));
    else
      printf("Column %i was not read like numbers:\n",I);
      printf("«%s»\n",SBtab.raw{2:end,I});
      printf("trying str2double.\n");
      c(:,i)=cellfun(@str2double,SBtab.raw(3:end,I));
    endif
  endfor
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

function [k]=get_default_parameters(Parameter)
  assert(strcmp(Parameter.TableName,"Parameter"))
  k=Parameter.num(:,1); 
endfunction

function [u,ID]=get_input(Input,Experiments)
  assert(strcmp(Input.TableName,'Input'));
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
  UI-=NumLimits(1); % this is an offset
  UI+=1;            % this is an index
  f=isfinite(UI);
  u=ones(nE,1)*DefaultInput';
  for i=1:nE
    u(i,f)=Experiments.num(i,UI(f));
  endfor
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
