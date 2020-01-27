function [I]=sort_by_correlation(cr,varargin)
  %% Usage: [I]=sort_by_correlation(cr,[n])
  %% given a correlation matrix _cr_,
  %% the function returns an index list
  %% that reorders the variables from high
  %% to low correlation.
  %% The index list starts with the highest
  %% absolute correlation pair and appends
  %% the index of the variable that is most
  %% correlated to the current end of the list.
  %%
  %% Optionally, the return list stops at n.
 n=size(cr);
 [j,i]=meshgrid(1:n(1),1:n(2));
 k=find(triu(ones(n(1)),1));
 [cc,cci]=sort(abs(cr(k)),'descend');
 if not(isempty(varargin))
  m=varargin{1};
 else
  m=n(1);
 end%if
 [i,j]=ind2sub(n,k(cci));
 I=zeros(1,m);
 t=i(1);
 for l=1:m
  I(l)=t;
  %fprintf('l=%i, k=%i, length(j)=%i\n',l,k,length(j));
  o=((i==t)|(j==t)); % get a sorted list of indices that are highly correlated with Sample member k
  if ~isempty(o)
   s=Merge(i(o)==t,j(o),i(o));
   t=s(1);
   j(o)=[]; % delete all pairs that involve current index
   i(o)=[]; %
  end%if
 end%for
end%function

function r=Merge(c,t,f)
  N=length(c);
  r=NaN(1,N);
  assert(islogical(c));
  for i=1:N
    if c(i)
      r(i)=t(i);
    else
      r(i)=f(i);
    end
  end%for
end%function
