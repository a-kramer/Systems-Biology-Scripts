function [v]=as_column(sbtab,name)
  v=cat(1,sbtab.(name));
endfunction
