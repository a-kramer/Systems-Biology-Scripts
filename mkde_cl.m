function [kde]=mkde_cl(X,k)
  ## This function creates a density estimator which takes
  ## multimodality into account, it requires a clustering method,
  ## currently kmeans from the statistics package
  ##
  ## Usage: [kde]=mkde(X,k)
  ## k: number of clusters to try
  ## X: M×N Sample of column vectors x (of size M). returns a function
  ## handle: kde(x), where x is an M-sized column vector. The function handle
  ## will contain the sample X as an implicite argument and not
  ## reference the workspace.
  ##
  pkg load statistics
  [M,N]=size(X);
  assert(N>M);
  [cluster.idx, cluster.centers, cluster.sumd, cluster.dist] = kmeans (X',k);
  Y=cell(k,1);
  B=cell(k,1);
  D2=cell(k,1);
  n=NA(k,1);
  for i=1:k
    Y{i}=X(:,cluster.idx==i);
    [m,n(i)]=size(Y{i});
    assert(m==M);
    C=cov(Y{i}')*n(i)^(-2/(m+4));       # kernel choice
    B{i}=sqrtm(C);                   #
    D2{i}=sqrt(2*pi)^m*sqrt(det(C)); # normalisation constant
  endfor
  sn=1/sum(n);
  kde=@(x) sum(cellfun(@(B,X,D2) sum(exp(-0.5*sumsq(B\bsxfun(@minus,x,X),1))/D2),B,Y,D2)*sn);
endfunction
