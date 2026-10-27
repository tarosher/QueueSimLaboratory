function sweepResult = sweepPolicySensitivity(baseConfig,scenarios,sweep,options)
%SWEEPPOLICYSENSITIVITY Factor-at-a-time comparison with paired policy arms.
% sweep.kind: 'arrivalRate' or 'serverCount'
% sweep.values: increasing positive rates or integer server counts
% sweep.serverSpeeds: fixed speed catalog for serverCount, prefix selected.
% At a given factor level, common random numbers match all policy arms;
% NO pairwise inference is claimed BETWEEN different sweep levels.
if nargin<4, options=struct(); end
if ~isstruct(sweep) || ~isscalar(sweep) || ~isfield(sweep,'kind') || ...
        ~isfield(sweep,'values') || ~isnumeric(sweep.values) || ...
        ~isvector(sweep.values) || isempty(sweep.values) || ...
        ~all(isfinite(sweep.values(:))) || any(sweep.values(:)<=0) || ...
        ~all(diff(sweep.values(:))>0)
    error('qsim:InvalidSweep','Specify strictly increasing positive sweep.values.');
end
values=sweep.values(:)';
if ~isstruct(options) || ~isscalar(options)
    error('qsim:InvalidSweep','options must be a scalar struct.');
end
if ~isfield(options,'nRep'), options.nRep=12; end
if ~isfield(options,'seedStart'), options.seedStart=52000; end
if ~isfield(options,'confidence'), options.confidence=0.95; end
if ~isfield(options,'referenceIndex'), options.referenceIndex=1; end
if ~isfield(options,'serviceLevelThreshold'), options.serviceLevelThreshold=5; end
if strcmp(sweep.kind,'arrivalRate')
    if ~strcmp(baseConfig.source.type,'poisson')
        error('qsim:InvalidSweep','arrivalRate sweep requires a Poisson source.');
    end
elseif strcmp(sweep.kind,'serverCount')
    if any(values~=floor(values)) || ~isfield(sweep,'serverSpeeds') || ...
            ~isnumeric(sweep.serverSpeeds) || ...
            ~isvector(sweep.serverSpeeds) || ...
            numel(sweep.serverSpeeds)<max(values) || ...
            any(~isfinite(sweep.serverSpeeds(:))) || any(sweep.serverSpeeds(:)<=0)
        error('qsim:InvalidSweep','serverCount needs integer values and a positive speed catalog.');
    end
else
    error('qsim:InvalidSweep','Unknown sweep kind; use arrivalRate or serverCount.');
end
nValues=numel(values); nArms=numel(scenarios);
metrics={'meanWait','p95Wait','meanQueueLength','meanUtilization','rejectionRate'};
mu=NaN(nValues,nArms,numel(metrics));
low=mu; high=mu;
loadRatio=zeros(nValues,1);
nodes=zeros(nValues,1);
pairedWait=NaN(nValues,nArms); pairedLow=pairedWait; pairedHigh=pairedWait;
for k=1:nValues
    c=baseConfig;
    if strcmp(sweep.kind,'arrivalRate')
        c.source.rate=values(k);
    else
        c.network.nodes.nServers=values(k);
        c.network.nodes.serverSpeedMultipliers=reshape(sweep.serverSpeeds(1:values(k)),1,[]);
    end
    cfgServiceMean=qsim.core.expectedServiceMean(c.network.nodes);
    speeds=c.network.nodes.serverSpeedMultipliers;
    if isempty(speeds), speeds=ones(1,c.network.nodes.nServers); end
    loadRatio(k)=c.source.rate*cfgServiceMean/sum(speeds);
    nodes(k)=c.network.nodes.nServers;
    % Reuse the same seed sequence across factor levels deliberately;
    % only within-level paired scenario contrasts are interpreted.
    r=qsim.experiments.comparePolicies(c,scenarios,options);
    for j=1:nArms
        for m=1:numel(metrics)
            ci=r.summary(j).metrics.(metrics{m});
            mu(k,j,m)=ci.mean;
            low(k,j,m)=ci.lower;
            high(k,j,m)=ci.upper;
        end
        if j~=options.referenceIndex
            d=r.raw.meanWait(:,j)-r.raw.meanWait(:,options.referenceIndex);
            dc=qsim.stats.meanCI(d,options.confidence);
            pairedWait(k,j)=dc.mean;
            pairedLow(k,j)=dc.lower;
            pairedHigh(k,j)=dc.upper;
        end
    end
end
sweepResult=struct('kind',sweep.kind,'values',values, ...
    'names',{ {scenarios.name} },'metrics',{metrics}, ...
    'mean',mu,'lower',low,'upper',high,'offeredLoad',loadRatio, ...
    'nServers',nodes,'pairedMeanWait',pairedWait, ...
    'pairedLower',pairedLow,'pairedUpper',pairedHigh, ...
    'options',options, ...
    'caveat','Finite-horizon independent replications, CRN only within each factor level; do not claim across-level paired differences.');
end
