function validateConfig(c)
%VALIDATECONFIG M2 single-node or M4 opt-in DAG configuration.
if isstruct(c) && isscalar(c) && isfield(c,'extensions') && ...
        isstruct(c.extensions) && isfield(c.extensions,'network') && ...
        isequal(c.extensions.network,true)
    qsim.network.validateNetworkConfig(c);
    return;
end
require(isstruct(c) && isscalar(c),'Config must be a scalar struct.');
needed={'version','simulation','source','network','randomness','extensions','output'};
for k=1:numel(needed)
    require(isfield(c,needed{k}),'Missing Config.%s',needed{k});
end
require(strcmp(c.version,'0.2'),'Unsupported Config.version.');
s=c.simulation;
require(isFiniteScalar(s.arrivalHorizon) && s.arrivalHorizon>0,'Invalid arrivalHorizon.');
require(isFiniteScalar(s.observationHorizon) && s.observationHorizon>=s.arrivalHorizon, ...
    'observationHorizon must be >= arrivalHorizon.');
require(any(strcmp(s.stopMode,{'drain','truncate'})),'Invalid stopMode.');
require(isFiniteScalar(s.seed) && s.seed>=0 && s.seed==floor(s.seed) && s.seed<=2^32-1,'Invalid seed.');
require(isFiniteScalar(s.tolerance) && s.tolerance>0,'Invalid tolerance.');
require(isPosInt(s.maxEntities),'Invalid maxEntities.');
require(isPosInt(s.maxEvents),'Invalid maxEvents.');
require(isFiniteScalar(s.warmup) && s.warmup==0, ...
    'Nonzero warmup is not yet implemented; use warmup=0 in M2.');
require(isFiniteScalar(s.nRep) && s.nRep==1,'M2 supports one replication per qsim.run call; M3 adds a runner.');
require(strcmp(c.randomness.method,'PRNG'),'M2 supports PRNG only.');
require(isfield(c.output,'retainEntityRecords') && islogical(c.output.retainEntityRecords) && isscalar(c.output.retainEntityRecords), ...
    'output.retainEntityRecords must be logical.');

src=c.source;
require(any(strcmp(src.type,{'poisson','schedule','renewal'})),'Unsupported source.type.');
switch src.type
    case 'poisson'
        require(isFiniteScalar(src.rate) && src.rate>=0,'Poisson rate must be nonnegative.');
    case 'schedule'
        require(isnumeric(src.times) && isreal(src.times) && ...
            (isempty(src.times) || isvector(src.times)) && ...
            all(isfinite(src.times(:))) && all(src.times(:)>=0) && ...
            all(diff(src.times(:))>=0), ...
            'Scheduled times must be nonnegative, sorted, finite (or empty).');
        require(all(src.times(:)<=s.arrivalHorizon+s.tolerance),'Scheduled arrivals beyond arrivalHorizon.');
    case 'renewal'
        require(isfield(src,'interarrivalDistribution'), ...
            'Renewal source requires interarrivalDistribution.');
        validateDuration(src.interarrivalDistribution,false);
end
require(isstruct(c.network.nodes) && numel(c.network.nodes)==1, ...
    'Single-node mode requires exactly one node; enable extensions.network for a DAG.');
require(isempty(c.network.links),'Single-node mode does not accept graph links; use extensions.network.');
n=c.network.nodes;
require(ischar(n.id) && ~isempty(n.id),'Node ID must be nonempty char.');
require(isPosInt(n.nServers),'nServers must be a positive integer.');
require(any(strcmp(n.queueMode,{'pooledFIFO','separateFIFO'})), ...
    'queueMode must be pooledFIFO or separateFIFO.');
if strcmp(n.queueMode,'separateFIFO')
    require(isfield(n,'routingPolicy') && any(strcmp(n.routingPolicy, ...
        {'random','shortestQueue','shortestExpectedWait'})), ...
        'separateFIFO requires routingPolicy=random, shortestQueue or shortestExpectedWait.');
end
if isfield(n,'serverSpeedMultipliers') && ~isempty(n.serverSpeedMultipliers)
    speeds=n.serverSpeedMultipliers;
else
    speeds=ones(1,n.nServers); % permit older M1 config structs
end
require(isnumeric(speeds) && isreal(speeds) && numel(speeds)==n.nServers && ...
    all(isfinite(speeds(:))) && all(speeds(:)>0), ...
    'serverSpeedMultipliers must contain one finite positive value per server.');
if isfield(n,'routingServiceMean') && ~isnan(n.routingServiceMean)
    require(isFiniteScalar(n.routingServiceMean) && n.routingServiceMean>0, ...
        'routingServiceMean must be positive or NaN (infer).');
end
require(isCapacity(n.maxSystemOccupancy,1), ...
    'maxSystemOccupancy must be positive integer or Inf.');
require(isCapacity(n.maxWaiting,0), ...
    'maxWaiting must be nonnegative integer or Inf.');
validateDuration(n.serviceDistribution,true);
if strcmp(n.queueMode,'separateFIFO') && strcmp(n.routingPolicy,'shortestExpectedWait') && ...
        strcmp(n.serviceDistribution.type,'sequence')
    require(isfield(n,'routingServiceMean') && isFiniteScalar(n.routingServiceMean) && ...
        n.routingServiceMean>0, ...
        'Sequence service requires an explicit positive routingServiceMean for non-oracle routing.');
end

ext=c.extensions;
names={'network','resources','traffic','energy'};
for k=1:numel(names)
    f=names{k};
    require(isfield(ext,f) && islogical(ext.(f)) && isscalar(ext.(f)), ...
        'Config.extensions.%s must be logical.',f);
    if ext.(f)
        error('qsim:UnsupportedExtension', ...
            'Extension %s is not executable in this V0.2 build.',f);
    end
end
end

function validateDuration(d,allowSequence)
require(isstruct(d) && isscalar(d) && isfield(d,'type'), ...
    'Duration specification requires a type.');
allowed={'exponential','deterministic','uniform','lognormal'};
if allowSequence, allowed{end+1}='sequence'; end
require(any(strcmp(d.type,allowed)),'Unsupported duration distribution.');
switch d.type
    case 'exponential'
        require(isfield(d,'rate') && isFiniteScalar(d.rate) && d.rate>0, ...
            'Exponential rate must be >0.');
    case 'deterministic'
        require(isfield(d,'value') && isFiniteScalar(d.value) && d.value>0, ...
            'Deterministic duration must be >0.');
    case 'uniform'
        require(isfield(d,'min') && isfield(d,'max') && isFiniteScalar(d.min) && ...
            isFiniteScalar(d.max) && d.min>0 && d.max>=d.min, ...
            'Uniform duration requires 0<min<=max.');
    case 'lognormal'
        require(isfield(d,'muLog') && isfield(d,'sigmaLog') && isFiniteScalar(d.muLog) && ...
            isFiniteScalar(d.sigmaLog) && d.sigmaLog>=0, ...
            'Lognormal duration requires finite muLog and sigmaLog >=0.');
    case 'sequence'
        require(isfield(d,'values') && isnumeric(d.values) && isreal(d.values) && ...
            (isempty(d.values) || isvector(d.values)) && ...
            all(isfinite(d.values(:))) && all(d.values(:)>0), ...
            'Sequence service must be positive finite (or empty).');
end
end

function ok=isFiniteScalar(x)
ok=isnumeric(x) && isscalar(x) && isreal(x) && isfinite(x);
end
function ok=isPosInt(x)
ok=isFiniteScalar(x) && x>=1 && x==floor(x);
end
function ok=isCapacity(x,minimum)
ok=isnumeric(x) && isreal(x) && isscalar(x) && ...
    (isequal(x,Inf) || (isfinite(x) && x>=minimum && x==floor(x)));
end

function require(condition,message,varargin)
%REQUIRE Stable QueueSimLab configuration diagnostics across MATLAB versions.
% MATLAB's assertion identifiers differ by version and call form. Explicit
% qsim:InvalidConfig lets callers/tests distinguish malformed configs from
% qsim:UnsupportedExtension and internal engine invariant failures.
if ~condition
    error('qsim:InvalidConfig',message,varargin{:});
end
end
