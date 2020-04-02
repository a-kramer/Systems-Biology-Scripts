function [color_order]=pcplot_configure_colors(CMAP,P)
  c=size(CMAP,1);
  r=[min(P),max(P)];
  caxis(r);
  printf('range: [%i,%i]\n',r);
  lsc=linspace(r(1),r(2),c);
  color_order=fix_colormap(interp1(lsc,CMAP,P,'linear'));
endfunction
