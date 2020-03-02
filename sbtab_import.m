#!/usr/bin/octave-cli -q

function [sbtab,varargout] = sbtab_import(tsv_file)
  ##
  ## Usage: [sbtab] = sbtab_import(tsv_cstr)
  ##
  ##   input: tsv_file is a character array with the file name to import (a tab separated values [text file])
  ##  output: a structure array with fields corresponding to column headers
  assert(exist(tsv_file,"file"));
  tsv=fopen(tsv_file);
  ## Document Name
  str=fgetl(tsv);
  [RE.match,RE.tokens]=regexp(str,"^!!SBtab.*Document='([^']+)'",'match','tokens','once');
  DocumentName=RE.tokens{1};
  Table.Document=DocumentName;
  ## Table Properties
  [RE.match,RE.tokens]=regexp(str,"^!!SBtab.*TableName='([^']+)'",'match','tokens','once');
  Table.Name=RE.tokens{1};
  ##
  [RE.match,RE.tokens]=regexp(str,"^!!SBtab.*TableType='([^']+)'",'match','tokens','once');
  Table.Type=RE.tokens{1};
  ##
  [RE.match,RE.tokens]=regexp(str,"^!!SBtab.*TableTitle='([^']+)'",'match','tokens','once');
  Table.Title=RE.tokens{1};
  ## Print Information
  printf("Importing from file «%s» part of Document «%s»\n",tsv_file,DocumentName);
  printf("\tTable Name: «%s»\n",Table.Name);
  printf("\tTable Type: «%s»\n",Table.Type);
  printf("\tTable Title: «%s»\n",Table.Title);
  if (nargout>1)
    varargout{1}=Table;
  endif
  
  ## Header
  str=fgetl(tsv);
  printf("processing column header: «%s»\n",str);
  header=linetocstr(str);
  assert(~isempty(header));
  N=length(header);
  sbtab=struct();
  printf("The header contains the fields: ");
  for i=1:N
    printf("«%s»",header{i});
  endfor
  printf("\n");
  ## content lines
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
      endif
    endfor
    i=i+1;
  endwhile
  fclose(tsv);
endfunction

function [cstr]=linetocstr(str)
  cstr=[];
  not_a_comment=isempty(regexp(str,"^\\s*%",'start','once'));
  if not_a_comment
    cstr=ostrsplit(str,"\t");
  else
    printf("skipping comment line: «%s»\n",str);
  endif    
endfunction
