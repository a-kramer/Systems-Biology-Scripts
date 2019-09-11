fprintf('this loads functions related to reading SBtab files that contain experimental data.\n');
fprintf('\t· function [NormE,NormT,NormOut]=get_form_of_normalisation(eID,eName,NormalisedByExperiment,NormalisedByOutput)\n\
\t· function [Experiment]=get_time_series_data(E,yID,ErrorName,DefaultInput);\n\
\t· function [Experiment]=get_dose_response_data(E,yID,ErrorName,DefaultInput,uID,t);\n\
\t· function [Experiment,Norm]=get_experimental_data(Experiments,Output,ods_file_name,DefaultInput).\n');

function [NormE,NormT,NormOut]=get_form_of_normalisation(eID,eName,yID,NormalisedByExperiment,NormalisedByOutput)
  NE=length(eID);
  ny=length(yID);
  NormE=NA(NE,1);
  NormT=NA(NE,1)
  %%  l=cellfun(@isempty,NormalisedByExperiment);
  %%  [Norm{l}]=deal('');
  %% normalisation, by output
  if isempty(NormalisedByOutput)
    NormOut=1:ny;
  else
    NormOut=NA(ny,1);
    for i=1:ny
      nid=find(strcmp(NormalisedByOutput{i},yID),1);
      NormOut(i)=merge(not(isempty(nid)),nid,NA);
    end%for
  end%if
  display(NormOut);
  %%normalisation, by experiment and time
  if isempty(NormalisedByExperiment)
    NormET=[];
  else
    display(NormalisedByExperiment);
    Match=regexp(NormalisedByExperiment,'(?<Experiment>\\w+)(\\[(?<TimePoint>\\w+)\\])?','names');
    NormE=cellfun(@(c) merge(isempty(f=find(strcmp(merge(isempty(c.Experiment),'',c.Experiment),eID),1)),NA,f),Match);
  end%if
  display(NormE);
  display(NormT);    
end%function

function [Experiment]=get_time_series_data(E,yID,ErrorName,DefaultInput);
    ny=length(yID);
    data_I=NA(1,ny);
    stdv_I=NA(1,ny);
    %%E=get_table(eID{i},ods_file_name);
    assert(isfield(E,'raw'));
    TP=get_column('!TimePoint',E);
    for j=1:ny
      y_ref=strcat('>',yID{j});
      %%fprintf('looking up: «%s»\n',y_ref);
      l=find_column(y_ref,E);
      if isempty(l)
	data_I(j)=NA;	
      else
	data_I(j)=l;
      end%if
      l=find_column(ErrorName{j},E);
      stdv_I(j)=merge(isempty(l),NA,l); %% same for standard deviations
    end%for
    data_k=find(not(isna(data_I))); %% which outputs were measured at all?
    stdv_k=find(not(isna(stdv_I)));
    %%
    ct=find_column('!Time',E);
    fprintf('[get_experimental_data] %s: «!Time» is column %i.\n',eID{i},ct);
    t=get_num_column(ct,E);
    nt=length(t);
    %%
    Values=NA(nt,ny);
    StandardDeviations=NA(nt,ny);
    Values(:,data_k)=get_num_column(data_I,E);
    StandardDeviations(:,stdv_k)=get_num_column(stdv_I,E);
    %%
    Experiment.MeasuredOutput=data_k;
    Experiment.data=Values;
    Experiment.stdv=StandardDeviations;
    Experiment.time=t;
    Experiment.input=DefaultInput;
    Experiment.TimePoint=TP;
end%function

function [Experiment]=get_dose_response_data(E,yID,ErrorName,DefaultInput,uID,t);
    ny=length(yID);
    data_I=NA(1,ny);
    stdv_I=NA(1,ny);
    assert(isfield(E,'raw'));
    id=get_column('!ID',E); % local id in this file
    N=length(id);
    nu=length(uID);
    u=repmat(DefaultInput,N,1);
    display(uID);
    for j=1:ny
      y_ref=strcat('>',yID{j});
      %%fprintf('looking up: «%s»\n',y_ref);
      l=find_column(y_ref,E);
      data_I(j)=merge(isempty(l),NA,l);
      l=find_column(ErrorName{j},E);
      stdv_I(j)=merge(isempty(l),NA,l); % same for standard deviations
    end%for
    data_k=find(not(isna(data_I))); % which outputs were measured at all?
    stdv_k=find(not(isna(stdv_I)));
    %%
    for j=1:nu
      InputName=sprintf('>%s',uID{j})
      cu=find_column(InputName,E)
      if not(isempty(cu))
	d=j;
	fprintf('[get_experimental_data] «%s» is column %i.\n',InputName,cu);
	u(:,j)=get_num_column(cu,E);
      end%if
    end%for
    %%
    Values=NA(N,ny);
    StandardDeviations=NA(N,ny);
    display(data_I);
    Values(:,data_k)=get_num_column(data_I,E);
    display(stdv_I);
    StandardDeviations(:,stdv_k)=get_num_column(stdv_I,E);
    %%
    Experiment.MeasuredOutput=data_k;
    Experiment.data=Values;
    Experiment.stdv=StandardDeviations;
    Experiment.time=t;
    Experiment.input=u;
    Experiment.TimePoint=NA;
    Experiment.dose=d;
end%function


function [Experiment,Norm]=get_experimental_data(Experiments,Output,ods_file_name,DefaultInput,uID)
  assert(strcmp(Experiments.TableName,'Experiments'));
  assert(strcmp(Output.TableName,'Output'));
  yID=get_column('!ID',Output);
  ErrorName=get_column('!ErrorName',Output);
  NormalisedByOutput=get_column('!RelativeTo',Output);
  if not(isempty(NormalisedByOutput))
    fprintf('Output Normalisation:\n');fprintf('«%s»',NormalisedByOutput{:});
  else
    fprintf('Outputs are absolute measurements.\n');
  end%if
  ny=length(yID);
  fprintf('There are %i Output IDs.\n',ny);
  eID=get_column('!ID',Experiments);
  display(eID);
  eName=get_column('!Name',Experiments);  
  NE=length(eID);
  NormalisedByExperiment=get_column('!RelativeTo',Experiments);
  [NormE,NormOut]=get_form_of_normalisation(eID,eName,yID,NormalisedByExperiment,NormalisedByOutput);

  dtc=find_column('!Time',Experiments);
  DefaultTime=get_num_column(dtc,Experiments);
  
  E=get_sheets(ods_file_name,eID,eName);
  eType=get_column('!Type',Experiments);

  Experiment=struct('MeasuredOutput',cell(NE,1),'data',cell(NE,1),'stdv',cell(NE,1),'time',cell(NE,1),'input',cell(NE,1),'TimePoint',cell(NE,1),'dose',cell(NE,1),'Type',cell(NE,1));
  
  for i=1:NE
    %% get time series
    fprintf('Type of Experiment %i: «%s»\n',i,eType{i});
    switch (eType{i})
      case {'Dose Response'}
	%%                                              E,yID,ErrorName,DefaultInput,     uID,t)
	RET=get_dose_response_data(E(i),yID,ErrorName,DefaultInput(i,:),uID,DefaultTime(i));
	RET.Type=eType{i};
	Experiment(i)=RET;
	NormT=NA(NE,1);
      case {'Time Series'}
	RET=get_time_series_data(E(i),yID,ErrorName,DefaultInput(i,:));
	RET.Type=eType{i};
	Experiment(i)=RET;
	l=not(isna(NormE));
	NormT(l)=cellfun(@(m,j) merge(isempty(f=find(strcmp(m.TimePoint,Experiment(i).TimePoint),1)),NA,f),Match(l),num2cell(NormE(l)));
      otherwise
	error('Experiment Type unknown or unspecified: «%s»\n',eType{i});	
    end%switch
  end%for
  
  if not(isempty(NormE))
    for i=1:NE
      fprintf('plotting data for experiment «%s»\n',eID{i});
      if isna(NormT(i))
	T=1:length(Experiment(i).time);
      else
	T=NormT(i);
      end%if
      if not(isna(j=NormE(i)))
	Experiment(i).data=bsxfun(@rdivide,Experiment(i).data,Experiment(j).data(T,:));
	Experiment(i).stdv=bsxfun(@rdivide,Experiment(i).stdv,Experiment(j).data(T,:)); %% this is slightly wrong, but a good approsimation and easy to write	
      end%if
      figure(i); clf;
      k=isfinite(Experiment(i).stdv(1,:));
      display(k);
      fprintf('Measured Outputs:'); fprintf(' «%s»',yID{k}); fprintf('\n');
      subplot(1,2,1); cla;
      plot(Experiment(i).data,';;');
      subplot(1,2,2); cla;
      fprintf('sizes [time,input,data,stdv]: ');
      display(size(Experiment(i).time));
      display(size(Experiment(i).input));
      display(size(Experiment(i).data(:,k)));
      display(size(Experiment(i).stdv(:,k)));
      nk=length(k);
      switch(Experiment(i).Type)
	case {'Dose Response'}
	  d=Experiment(i).dose;	  
	  display(d)
	  eh=errorbar(Experiment(i).input(:,d),Experiment(i).data(:,k),Experiment(i).stdv(:,k),'~+');
	case {'Time Series'}
	  eh=errorbar(Experiment(i).time*ones(1,nk),Experiment(i).data(:,k),Experiment(i).stdv(:,k),'~+');
	otherwise
	  error('unknown experiment type');
      end%switch
      set(eh,'linestyle','none');
      title(eID{i});
      xlabel('time');
      ylabel(sprintf('%s ',yID{k}));
    end%for
  end%if
  
  Norm.T=NormT;
  Norm.E=NormE;
  Norm.O=NormOut;
end%function
