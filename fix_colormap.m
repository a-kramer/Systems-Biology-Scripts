function [CMAP]=fix_colormap(color_order)
  ## Usage: [CMAP]=fix_colormap(CMAP)
  ##
  ##  sometimes a colormap that is made via interp1 function
  ##  contains values outside of the permitted range
  ##  I don't know why or in which cases.
  ##  this function fixes that error.
  if any(color_order(:)>1)
    color_order(color_order>1)=1; 
    warning('color_order > 1 detected (corrected).');
  endif
  if any(color_order(:)<0)
    color_order(color_order<0)=0;
    warning('color_order < 0 detected (corrected).');
  endif
  CMAP=color_order;
endfunction
