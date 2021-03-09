function [sbtab,varargout] = sbtab_from_tsv(tsv_file)
  %
  % Usage: [sbtab] = sbtab_import(tsv_cstr)
  %
  %   input: tsv_file is a character array with the file name to import (a tab separated values [text file])
  %  output: a structure array with fields corresponding to column headers
  assert(exist(tsv_file,'file'));
  tsv=fopen(tsv_file);
  % Document Name
  str=fgetl(tsv);
  [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*Document=''([^'']+)''','match','tokens','once');
  DocumentName=RE.tokens{1};
  fprintf('Importing from file «%s» part of Document «%s»\n',tsv_file,DocumentName);
  % Table Properties
  if (nargout>1)
    Table.Document=DocumentName;
    [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*TableName=''([^'']+)''','match','tokens','once');
    Table.Name=RE.tokens{1};
    %
    [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*TableType=''([^'']+)''','match','tokens','once');
    Table.Type=RE.tokens{1};
    %
    [RE.match,RE.tokens]=regexp(str,'^!!SBtab.*TableTitle=''([^'']+)''','match','tokens','once');
    Table.Title=RE.tokens{1};
    % Print Information
    fprintf('\tTable Name: «%s»\n',Table.Name);
    fprintf('\tTable Type: «%s»\n',Table.Type);
    fprintf('\tTable Title: «%s»\n',Table.Title);
    varargout{1}=Table;
  end%if
  % Header
  str=fgetl(tsv);
  cmnt=strfind(str,'%');
  if ~isempty(cmnt)
    str=str(1:cmnt-1);
  end%if
  fprintf('processing column header: «%s»\n',str);
  header=linetocstr(str);
  assert(~isempty(header));
  header=regexprep(header,'[^A-Za-z0-9]','');
  N=length(header);
  sbtab=struct();
  fprintf('The header contains the fields: ');
  for i=1:N
    fprintf('«%s»',header{i});
  end%for
  fprintf('\n');
  % content lines
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
  cmnt=strfind(str,'%');
  if ~isempty(cmnt)
    str=strtrim(str(1:cmnt-1));
  end%if
  if ~isempty(str)
    cstr=strsplit(str,'\t');
  else
    fprintf('skipping comment line.\n');
  end%if    
end%function
