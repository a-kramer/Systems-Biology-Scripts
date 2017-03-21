function [varargout]=pwe(val,dval,varargin)
%% Usage: {[s]=}pwe(val,dval,[option,value,…])
%%   converts a pair of value val and its uncertainty dval into concise notation
%%   example: 1.2345 ± 0.0023 → 1.2345(23)
%%
%%  When given an output argument, the result string is returned, otherwise it is printed.
%%
%%  options:
%%  {'separator','E','x'} sets the string that separates the value from
%%                        the magnitude. The default is ' × '
%%  example: pwe(0.001,0.0001,'separator','\\times ')
%%  will print: 1.000(100)\times 10^{-3}
%%
s=floor(log10(val));  % magnitude of value
ds=ceil(log10(dval)); % magnitude of uncertainty
digits=s-ds+2;
x=' × ';
for i=1:2:length(varargin)
 opt=varargin{i};
 switch opt
 case {'x','separator','E'}
  x=varargin{i+1};
 otherwise
  printf('known options are: \n');
  printf('%s\n',{'x','separator','E'});
 endswitch
end%for
fmt=sprintf('%%%i.%if(%%i)%s10^{%i}\n',digits+1,digits,x,s);
if (nargout==1)
  varargout{1}=sprintf(strtrim(fmt),val*10^(-s),round(dval*10^(2-ds)));
else
  printf(fmt,val*10^(-s),round(dval*10^(2-ds)));
end%if
end%function
