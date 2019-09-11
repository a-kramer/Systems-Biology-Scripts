function [A,K,x,PDF]=sample_with_linear_constraint(M,l,request)
  %% l (row-vector) is the linear property that has to be true in the following way:
  %%    l*x=0       (x)
  %% this function calculates a matrix A, with the goal of sampling
  %%  x from an n-1 dimensional space, s.t. l*x is exactly true.
  %%
  %%
  %% a lot of this code is to test the properties of samples that are returned
  %% plots will be made
  %% empirical density functions will be calculated
  %%
  pkg load statistics
  n=length(l);
  A=null(l);
  N=size(A,2);
  if isfield(request,'mu') && (isfield(request,'Sigma') || isfield(request,'sigma'))
    mu=request.mu;
    assert(n==size(mu,1));
    if isfield(request,'Sigma')
      Sigma=request.Sigma;
    else
      Sigma=diag(request.sigma.^2);
    end%if
    S=@(m,H) A*(m+H*randn(N,M));
    %% to test that l*S is near 0:
    z=l*S(zeros(N,1),eye(N));
    figure(1); clf;
    hist(z);
    title('l*S; this should be zero');
    figure(2); clf;
    hist(S(zeros(N,1),eye(N))');
    title('this is S(mu=0,Sigma=1)')
    m=A\mu;
    %%display(m)
    H=chol(HH=A'*Sigma*A)';
    display(HH-H*H')
    TargetProperty=norm(A*H*H'*A'-Sigma);
    SigmaMissmatch=norm(H*H'-A'*Sigma*A);
    fprintf('norm(A*H*H'*A'-Sigma)=%g\n',TargetProperty);
    fprintf('norm(H*H'-A'*Sigma*A)=%g\n',SigmaMissmatch);
    K=S(m,H);
    %% check sample properties:
    fprintf('actual sample mean:\n');
    display(mean(K'));
    fprintf('requested mean:\n');
    display(mu);
    fprintf('actual covariance:\n');
    display(cov(K'));
    fprintf('requested covariance:\n');
    display(Sigma);
  elseif isfield(request,'min') && isfield(request,'max')
    S=@(b) A*(b(:,1)+diff(b,1,2)'*rand(N,M)) % b = [lower_bound,upper_bound]
    L=request.min;
    U=request.max;
    assert(n==length(L));
    assert(n==length(U));
    AL=A\L
    AU=A\U
    %B=NA(N,2);
    B=cat(2,min(AL,AU),max(AL,AU))
    K=S(B);
    fprintf('requested lower bound:');
    display(L);
    fprintf('actual min:')
    display(min(K'))
    fprintf('requested upper bound:');
    display(U);
    fprintf('actual max:');
    display(max(K'));
  end%if
    figure(3); clf;
    hist(K');
    figure(4); clf; hold on;
    %% density plots:
    pdf=cell(n,1);
    x=linspace(min(K(:)),max(K(:)),256)';
    for i=1:n
      PDF{i}=fitgmdist(K(i,:)',k=4); %empirical_pdf(x, K(i,:));
      p=PDF{i}.pdf(x);
      plot(x,p,'-;;');
    end%for
    Y=ylim();
    if exist('mu','var')
      for i=1:n
	plot(mu(i)*ones(2,1),Y','--r;mu;','linewidth',2);
      end%for
    elseif exist('L','var') && exist('U','var')
      %%for i=1:n
      errorbar(0.5*(L+U),mean(Y)+0.1*randn(n,1)*diff(Y),U-L,'%+');
      %%end%for
    end%if
    hold off;
    title(sprintf('Gaussian Mixture with %i components',k));
end%function
