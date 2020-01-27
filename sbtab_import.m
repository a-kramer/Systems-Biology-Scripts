function [sbtab] = sbtab_import(tsv_file)
  %%
  %% Usage: [sbtab] = sbtab_import(tsv_cstr)
  %%
  %%   input: tsv_file is a character array with the file name to import (a tab separated values [text file])
  %%  output: a structure array with fields corresponding to column headers
  assert(exist(tsv_file,'file'));
  tsv=fopen(tsv_file);
  %% Document Name
  str=fgetl(tsv);
  [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*Document=''([^'']+)''','match','tokens','once');
  DocumentName=RE.tokens{1};
  fprintf('Importing from file «%s» part of Document «%s»\n',tsv_file,DocumentName);
  %% Header
  str=fgetl(tsv);
  fprintf('processing column header: «%s»\n',str);
  header=linetocstr(str);
  assert(~isempty(header));
  N=length(header);
  sbtab=struct();
  fprintf('The header contains the fields: ');
  for i=1:N
    fprintf('«%s»',header{i});
  end%for
  fprintf('\n');
  %% content lines
  i=1;
  while ~feof(tsv)
    str=fgetl(tsv);
    cstr=linetocstr(str);
    for j=1:length(cstr)
      d=str2double(cstr{j});
      if isnan(d)
	sbtab(i).(header{j})=cstr{j};	
      else
	sbtab(i).(header{j})=d;
      end%if
    end%for
    i=i+1;
  end%while
  fclose(tsv);
end%function

function [cstr]=linetocstr(str)
  cstr=[];
  not_a_comment=isempty(regexp(str,'^\\s*%','start','once'));
  if not_a_comment
    cstr=ostrsplit(str,'\t');
  else
    fprintf('skipping comment line: «%s»\n',str);
  end%if    
end%function
