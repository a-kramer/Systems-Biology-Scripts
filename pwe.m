function [varargout]=pwe(val,dval)
% Usage: pwe(val,dval)
%   converts a pair of value val and its uncertainty d1val into concise notation
%   example: 1.2345 ± 0.0023 → 1.2345(23)  
s=floor(log10(val));  % magnitude of value
ds=ceil(log10(dval)); % magnitude of uncertainty
digits=s-ds+2;

fmt=sprintf("%%%i.%if(%%i) × 10^{%i}\n",digits+1,digits,s);
if (nargout==1)
  varargout{1}=sprintf(strtrim(fmt),val*10^(-s),round(dval*10^(2-ds)));
else
  printf(fmt,val*10^(-s),round(dval*10^(2-ds)));
end%if
end%function
