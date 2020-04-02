function [S,P]=from_nd_array(Sample,P,I)
  ## Usage: [S,P]=from_nd_array(Sample,P,I)
  ##
  ##  The Sample in the arguments of plcplot functions
  ##  may be a 3-dimensional object. Alongside the 3rd dim
  ##  subsets of a big sample may be stored if the subsets
  ##  are of similar importance and should be displayed
  ##  in an interweaving manner.
  sz=size(Sample)
  o=size(Sample,3);
  S=NA(sz); # same size as Sample
  for i=1:o
    Ii=I(1,:,i);
    S(:,:,i)=Sample(:,Ii,i);
    P(1,:,i)=P(1,Ii,i);
  endfor
  if o>1
    # transpose
    S=permute(S,[1,3,2]);
    P=permute(P,[1,3,2]);
    # reshape
    S=reshape(S,sz(1),[]);
    P=reshape(P,1,[]);
  endif
endfunction
