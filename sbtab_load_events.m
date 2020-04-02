function [event]=load_events(sv_ids,input_ids,sbtab)
  ## Usage: load_events(experiments, sbtab)
  ## where
  ##   experiments: a struct array as retruned from sbtab_import()
  ##                holds the "Experiments" Table for a model
  ##       svnames: the names of state variables in the ode
  ##        unames: the names of the input variables
  ##         sbtab: a struct of sbtab tables that must contain the event tables
  ##                mentioned in experiments 
  ## returns:
  ##   ev: struct array of sorted event lines as they apply to a simulation
  ##       ev(i).time(j) is the j'th event's time for experiment i
  ##       ev(i).operation(j,k) is the operation [=+-*/] at timepoint j for target k
  ##       ev(i).target(j,k) is the index of the affected quantity in its vector
  ##       ev(i).effect(j,k) is the affected quantity 'u' (input) or 'x' (state variable)
  assert(isstruct(sbtab) && isfield(sbtab,"Experiments"));
  experiments=sbtab.Experiments;
  assert(isfield(experiments,"!Event"))
  nE=length(experiments);
  for i=1:nE
    ev=ostrsplit(experiments(i).("!Event")," ",true);
    N=length(ev);
    t=cell(N,1);
    o=cell(N,1);
    tgt=cell(N,1);
    type=cell(N,1);
    val=cell(N,1);
    for j=1:N
      e=sbtab.(ev{j});
      t{j}=cat(1,e.("!Time"));
      nt=length(t{j});
      fn=fieldnames(e);
      tok=regexp(fn,">([^:]+):(\\w+)",'tokens','once');
      l=~cellfun(@isempty,tok);
      M=sum(l);
      tok=tok(l); # remove all empty matches
      fn=fn(l);
      o{j}=NA(nt,M);
      tgt{j}=NA(nt,M);
      type{j}=NA(nt,M);
      val{j}=NA(nt,M);
      for k=1:M
	o{j}(:,k)=determine_operation(tok{k}{1});
	[tgt{j}(:,k),type{j}(:,k)]=determine_target(tok{k}{2},sv_ids,input_ids);
	val{j}(:,k)=cat(1,e.(fn{k}));
      endfor
    endfor
    time=cat(1,t{:});
    operation=cat(1,o{:});
    target=cat(1,tgt{:});
    effect=cat(1,type{:});
    value=cat(1,val{:});
    [~,I]=sort(time);
    event(i).time=time(I);
    event(i).operation=operation(I,:);
    event(i).target=target(I,:);
    event(i).effect=effect(I,:);
    event(i).value=value(I,:);
  endfor
endfunction


function [tgt,type]=determine_target(target,svnames,unames)
  if (any(g=strcmp(target,unames)))
    tgt=find(g,1);
    type="u";
  elseif (any(g=strcmp(target,svnames)))
    tgt=find(g,1);
    type="x";
  else
    error("target not found: «%s».",tgt_k);
  endif  
endfunction

function [op]=determine_operation(o_k)
  switch(o_k)
    case "SET"
      op='=';
    case "ADD"
      op='+';
    case "SUB"
      op='-';
    case "MUL"
      op='*';
    case "DIV"
      op='/';
    otherwise
      op=NA;
  endswitch
endfunction
