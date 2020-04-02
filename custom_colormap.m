function [CMAP]=custom_colormap(val,clr,N)
  cs=linspace(0,1,N);
  CMAP=interp1(val,clr,cs);
endfunction
