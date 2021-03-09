function [SBtabDoc,name]=sbtab_doc(tsv_file_cstr)
  % Usage: [doc]=sbtab_doc(tsv_file_cstr)
  %
  % loads all sbtab tables referenced in tsv_file_cstr (a cell array
  % of char arrays).
  %
  % returns a struct doc, where each field is one sbtab data
  % structure (sbtabs are represented as struct arrays with fields
  % corresponding to column headers)
  N=length(tsv_file_cstr);
  name=[];
  SBtabDoc=struct();
  for i=1:N
    assert(exist(tsv_file_cstr{i},'file'));
    [data,Table]=sbtab_from_tsv(tsv_file_cstr{i});
    Table.Name
    Name=regexprep(Table.Name,'[^A-Za-z0-9]','_');
    assert(not(isfield(SBtabDoc,Name)));
    SBtabDoc.(Name)=data;
    if (isempty(name))
      name=Table.Document;
    elseif (~strcmp(name,Table.Document))
      warning('table in file «%s» belongs to a different Document: %s.',tsv_file_cstr{i},Table.Document);
    end%if
  end%for
end%function
