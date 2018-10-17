function [varargout]=pwe(val,dval,varargin)
  %% Usage: {[s]=}pwe(val,dval,[option,value,…])
  %%   converts a pair of value val and its uncertainty dval into concise notation
  %%   example: 1.2345 ± 0.0023 → 1.2345(23)
  %%
  %%  When given an output argument, the result string is returned, otherwise it is printed.
  %%
  %%  options:
  %%  {'separator','x'} sets the string that separates the value from
  %%                    the magnitude. The default is ' × 10^{magnitude}'
  %%                    pwe(0.001,0.0001,'separator','\\times ')
  %%                    prints 1.00(10)\times 10^{-3}
  %%  {'E'}             prints valueEmagnitude: 1.20(30)E-4
  %%                    value can be the letter
  %%                    pwe(value,error,'E','e') prints 1.20(30)e-4
  %%                    pwe(value,error,'E',[])  prints 1.20(30)E-4
  %%  {'pre_sep_post'}  allows more customization
  %%                    the value is a cell(4,1) array of strings
  %%                    {pre-value, separator, post-exponent, post-number}
  %%                    Example:
  %%                    pwe(12e-5,3e-5,'pre_sep_post',{'','×10^{','}','.'})
  %%                    prints «1.20(30)×10^{-4}.»
  %%
  %%
  if (isempty(dval) && length(val)==2)
    dval=val(2);
    val=val(1);
  endif
  s=floor(log10(abs(val)));  % magnitude of value
  ds=ceil(log10(dval)); % magnitude of uncertainty
  int_dval=round(dval*10^(2-ds));
  m=[mod(int_dval,10),mod(int_dval,100)]==0;
  int_dval/=10^sum(m);
  digits=s-ds+sum(not(m));
  x={'',' × 10^{','}',''}; % pre number, separator between number and exponent, post exponent, post number
  for i=1:2:length(varargin)
    opt=varargin{i};
    switch opt
      case {'x','separator'}
	x{1}='';
	x{2}=varargin{i+1};
	x{3}='';
      case {'E'}
	x{1}='';
	x{2}=merge(length(varargin)==i || isempty(varargin{i+1}),'E',varargin{i+1});
	x{3}='';
      case {'pre_sep_post'}
	[x{:}]=deal(varargin{i+1}{:});
      case {'LaTeX'}
	x{2}='\times 10^{';
      case {'siunitx'}
	if (nargin>3)
	  pre='\SI{';
	  post=sprintf('{%s}',varargin{i+1});
	else
	  pre='\num{';
	  post='';
	end%if
	postE='}'
	x={pre,'e',postE,post};	
      otherwise
	  printf('known options are: \n');
	  printf('\t · %s\n',{'x','separator','E','pre_sep_post','LaTeX','siunitx'});
    endswitch
  endfor
  fmt=sprintf('%s%%%i.%if(%%i)%s\n',x{1},digits+1,digits,merge(s!=0,sprintf('%s%i%s',x{2},s,x{3}),x{4}));
  if (nargout==1)
    varargout{1}=strtrim(sprintf(fmt,val*10^(-s),int_dval));
  else
    printf(fmt,val*10^(-s),int_dval);
  endif
endfunction
