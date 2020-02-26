function [sbtab] = sbtab_import(tsv_file)
  %%
  %% Usage: [sbtab] = sbtab_import(tsv_cstr)
  %%
  %%   input: tsv_file is a character array with the file name to import (a tab separated values [text file])
  %%  output: a structure array with fields corresponding to column headers
  assert(logical(exist(tsv_file,'file')));
  tsv=fopen(tsv_file);
  %% Document Name
  str=fgetl(tsv);
  [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*Document=''([^'']+)''','match','tokens','once');
  DocumentName=RE.tokens{1};
  fprintf('Importing from file «%s» part of Document «%s»\n',tsv_file,DocumentName);
  %% Header
  str=fgetl(tsv);
  fprintf('processing column header: «%s»\n',regexprep(str,'\t',' '));
  header=linetocstr(str);
  assert(~isempty(header));
  header=regexprep(header,'[^A-Za-z0-9]','');
  N=length(header);
  sbtab=struct();
  fprintf('The header contains the cleaned up fields: ');
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
          switch(cstr{j})
              case {'FALSE','false'}
                  sbtab(i).(header{j})=false;
              case {'TRUE','true'}
                  sbtab(i).(header{j})=true;
              otherwise
                  sbtab(i).(header{j})=cstr{j};
          end
      else
	    sbtab(i).(header{j})=d;
      end%if
    end%for
    i=i+1;
  end%while
  fclose(tsv);
end%function

function [cstr]=linetocstr(str)
  cstr=strsplit(str,'%');
  str=cstr{1};
  not_a_comment=isempty(regexp(str,'^\\s*%','start','once'));
  if not_a_comment
    cstr=strsplit(str,'\t','CollapseDelimiters',false);
  else
    fprintf('skipping comment line: «%s»\n',str);
    cstr=[];
  end%if    
end%function
