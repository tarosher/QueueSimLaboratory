function result = comparePolicies(baseConfig,scenarios,options)
%COMPAREPOLICIES Paired policy comparison using common random numbers (CRN).
% result=qsim.experiments.comparePolicies(config,scenarios,options)
%
% Each replication independently reseeds qsim.run with the SAME seed for
% every scenario, so exogenous arrival timestamps and customer service
% requirements are identical across policies. Random lane-selection draws
% occur after arrival/service generation and may differ across policies.
% This is a finite-horizon, initially empty, drain-mode experiment;
% no steady-state inference is claimed. Paired differences are scenario-ref.
%
% options: nRep (>=2), confidence (0,1), seedStart, referenceIndex,
%          serviceLevelThreshold (minutes; default 5).
if nargin<2 || isempty(scenarios)
    scenarios=qsim.experiments.defaultPolicyScenarios();
end
if nargin<3, options=struct(); end
require(isstruct(options) && isscalar(options),'options must be a scalar struct.');
options=withDefault(options,'nRep',40);
options=withDefault(options,'confidence',0.95);
options=withDefault(options,'seedStart',baseConfig.simulation.seed);
options=withDefault(options,'referenceIndex',1);
options=withDefault(options,'serviceLevelThreshold',5);
require(isscalar(scenarios) || isvector(scenarios),'scenarios must be a struct vector.');
require(isstruct(scenarios) && ~isempty(scenarios),'At least one scenario is required.');
require(isInt(options.nRep) && options.nRep>=2,'nRep must be >=2.');
require(isnumeric(options.confidence) && isscalar(options.confidence) && ...
    isfinite(options.confidence) && options.confidence>0 && options.confidence<1, ...
    'confidence must be between 0 and 1.');
require(isInt(options.seedStart) && options.seedStart>=0 && ...
    options.seedStart+options.nRep-1<=2^32-1, ...
    'Replication seed range must fit 0 to 2^32-1.');
require(isInt(options.referenceIndex) && options.referenceIndex>=1 && ...
    options.referenceIndex<=numel(scenarios),'referenceIndex out of range.');
require(isnumeric(options.serviceLevelThreshold) && isscalar(options.serviceLevelThreshold) ...
    && isfinite(options.serviceLevelThreshold) && options.serviceLevelThreshold>=0, ...
    'serviceLevelThreshold must be a nonnegative finite number.');
require(isfield(baseConfig,'output') && ...
    isfield(baseConfig.output,'retainEntityRecords') && ...
    isequal(baseConfig.output.retainEntityRecords,true), ...
    'retainEntityRecords=true is required for customer-level quantiles.');
require(strcmp(baseConfig.simulation.stopMode,'drain'), ...
    'M3 paired experiment requires stopMode=drain (uncensored cohorts).');
require(baseConfig.simulation.nRep==1, ...
    'Set simulation.nRep=1: use options.nRep for experiment repetitions.');
require(numel(baseConfig.network.nodes)==1 && isempty(baseConfig.network.links), ...
    'M3 experiments require a single-node M2 configuration.');
for j=1:numel(scenarios)
    item=scenarios(j);
    require(isfield(item,'name') && ischar(item.name) && ~isempty(strtrim(item.name)), ...
        'Each scenario must have a nonempty character name.');
    require(isfield(item,'queueMode') && ischar(item.queueMode) && ...
        any(strcmp(item.queueMode,{'pooledFIFO','separateFIFO'})), ...
        'Invalid scenario queueMode.');
    require(isfield(item,'routingPolicy') && ischar(item.routingPolicy), ...
        'Each scenario requires routingPolicy char.');
    if strcmp(item.queueMode,'separateFIFO')
        require(any(strcmp(item.routingPolicy, ...
            {'random','shortestQueue','shortestExpectedWait'})), ...
            'Invalid routingPolicy for separateFIFO.');
    end
end
require(numel(unique({scenarios.name}))==numel(scenarios), ...
    'Scenario names must be unique.');

% Preflight the full configuration of every arm before doing any simulation.
for j=1:numel(scenarios)
    cfg=configure(baseConfig,scenarios(j),options.seedStart);
    qsim.validateConfig(cfg);
end
metricKeys={'meanWait','p95Wait','meanSojourn','meanQueueLength', ...
    'meanUtilization','throughput','rejectionRate','serviceLevel'};
nRep=options.nRep;
nArms=numel(scenarios);
raw=struct();
for m=1:numel(metricKeys)
    raw.(metricKeys{m})=NaN(nRep,nArms);
end
seeds=options.seedStart+(0:nRep-1)';
exogenousMatched=true(nRep,1);
for rep=1:nRep
    referenceArrivals=[];
    referenceService=[];
    for arm=1:nArms
        cfg=configure(baseConfig,scenarios(arm),seeds(rep));
        out=qsim.run(cfg);
        e=out.entities;
        if arm==1
            referenceArrivals=e.arrivals;
            referenceService=e.serviceRequirements;
        elseif ~isequal(e.arrivals,referenceArrivals) || ...
                ~isequal(e.serviceRequirements,referenceService)
            error('qsim:CRNMismatch', ...
                'Replication %d: scenario %s has different exogenous inputs.', ...
                rep,scenarios(arm).name);
        end
        waits=e.wait(e.accepted & isfinite(e.wait));
        serviceLevel=NaN;
        if ~isempty(waits)
            serviceLevel=sum(waits<=options.serviceLevelThreshold)/numel(waits);
        end
        raw.meanWait(rep,arm)=out.system.meanWaitStartedCohort;
        raw.p95Wait(rep,arm)=qsim.stats.empiricalQuantile(waits,0.95);
        raw.meanSojourn(rep,arm)=out.system.meanSojournCompletedCohort;
        raw.meanQueueLength(rep,arm)=out.system.meanQueueLength;
        raw.meanUtilization(rep,arm)=out.system.meanServerUtilization;
        % Count completions observed during [0,Tobs], NOT all drain completions.
        raw.throughput(rep,arm)=sum(isfinite(e.departure) & ...
            e.departure<=cfg.simulation.observationHorizon)/ ...
            cfg.simulation.observationHorizon;
        raw.rejectionRate(rep,arm)=out.system.rejected/max(1,out.system.arrived);
        raw.serviceLevel(rep,arm)=serviceLevel;
    end
end
summary=repmat(struct('name','','queueMode','','routingPolicy','','metrics',struct()),1,nArms);
for arm=1:nArms
    summary(arm).name=scenarios(arm).name;
    summary(arm).queueMode=scenarios(arm).queueMode;
    summary(arm).routingPolicy=scenarios(arm).routingPolicy;
    for m=1:numel(metricKeys)
        key=metricKeys{m};
        values=raw.(key);
        summary(arm).metrics.(key)=qsim.stats.meanCI(values(:,arm),options.confidence);
    end
end
ref=options.referenceIndex;
paired=repmat(struct('name','','reference','','difference',struct()),1,nArms-1);
k=0;
for arm=1:nArms
    if arm==ref, continue; end
    k=k+1;
    paired(k).name=scenarios(arm).name;
    paired(k).reference=scenarios(ref).name;
    for m=1:numel(metricKeys)
        key=metricKeys{m};
        values=raw.(key);
        deltas=values(:,arm)-values(:,ref);
        paired(k).difference.(key)=struct('perReplication',deltas, ...
            'ci',qsim.stats.meanCI(deltas,options.confidence));
    end
end
result=struct();
result.options=options;
result.scenarios=scenarios;
result.metrics=metricKeys;
result.raw=raw;
result.summary=summary;
result.paired=paired;
result.reproducibility=struct('seeds',seeds,'crnChecked',all(exogenousMatched), ...
    'exogenousDefinition','identical arrivals and per-entity base service work');
result.caveats={ ...
    'Replication (not customer) is the statistical sampling unit.', ...
    'Student-t CIs describe finite-horizon independent replication means; no steady-state claim.', ...
    'Pairs use the same arrival/service inputs; routing uses its own policy decisions.', ...
    'Waiting-time metrics are conditional on accepted customers; compare rejectionRate too.', ...
    'Missing customer-level metrics yield NaN and are excluded pairwise (nMissing reported).', ...
    'Throughput counts only departures within observationHorizon, not drain tail.', ...
    'No universal claim that CRN always reduces paired-difference variance.'};
end

function cfg=configure(base,scenario,seed)
cfg=base;
cfg.simulation.seed=seed;
cfg.network.nodes.queueMode=scenario.queueMode;
cfg.network.nodes.routingPolicy=scenario.routingPolicy;
end
function options=withDefault(options,key,value)
if ~isfield(options,key), options.(key)=value; end
end
function tf=isInt(value)
tf=isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value==floor(value);
end
function require(condition,message)
if ~condition, error('qsim:InvalidExperiment','%s',message); end
end
