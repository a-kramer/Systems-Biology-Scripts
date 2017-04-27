function I=sort_by_correlation(cr,varargin)
 n=size(cr);
 [j,i]=meshgrid(1:n(1),1:n(2));
 j=triu(j,1,'pack');
 i=triu(i,1,'pack');
 k=sub2ind(n,i,j);
 [cc,cci]=sort(abs(cr(k)),'descend');
 if (length(varargin)>0)
  m=varargin{1};
 else
  m=n(1);
 endif
 [i,j]=ind2sub(n,k(cci));
 I=zeros(1,m);
 t=i(1);
 for l=1:m
  I(l)=t;
  #printf("l=%i, k=%i, length(j)=%i\n",l,k,length(j));
  o=((i==t)|(j==t)); # get a sorted list of indices that are highly correlated with Sample member k
  if (length(o)>0)
   s=merge(i(o)==t,j(o),i(o));
   t=s(1);
   j(o)=[]; # delete all pairs that involve current index k
   i(o)=[]; #
  endif
 endfor
endfunction
