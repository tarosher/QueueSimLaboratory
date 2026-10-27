function report = collectDiagnostics(config,scenarios,seeds)
%COLLECTDIAGNOSTICS Server-load and line-balance analysis per replication.
% Uses independent replication SEEDS; within replication policy arms use
% identical arrival and service inputs, following M3 CRN convention.
if nargin<3 || isempty(seeds), seeds=(41000:41011)'; end
if ~isnumeric(seeds) || ~isvector(seeds) || isempty(seeds) || ...
        any(~isfinite(seeds(:))) || any(seeds(:)<0) || ...
        any(seeds(:)~=floor(seeds(:))) || any(seeds(:)>2^32-1)
    error('qsim:InvalidDiagnostics','seeds must be a vector of valid integer RNG seeds.');
end
if ~strcmp(config.simulation.stopMode,'drain')
    error('qsim:InvalidDiagnostics','Use drain mode for consistent cohort diagnostics.');
end
nRep=numel(seeds); nArms=numel(scenarios); nServers=config.network.nodes.nServers;
perServer=zeros(nRep,nServers,nArms);
utilizationSpread=zeros(nRep,nArms);
strandedTimeFraction=zeros(nRep,nArms);
perLineMean=NaN(nRep,nServers,nArms);
for r=1:nRep
    for j=1:nArms
        c=config;
        c.simulation.seed=seeds(r);
        c.network.nodes.queueMode=scenarios(j).queueMode;
        c.network.nodes.routingPolicy=scenarios(j).routingPolicy;
        out=qsim.run(c);
        trace=qsim.analysis.reconstructTrace(out);
        strandedTimeFraction(r,j)=trace.strandedTimeFraction;
        u=out.system.perServerUtilization(:)';
        perServer(r,:,j)=u;
        utilizationSpread(r,j)=std(u,0,2);
        lines=out.system.meanQueueLengthByLine(:)';
        perLineMean(r,1:numel(lines),j)=lines;
    end
end
avgServer=zeros(nArms,nServers);
for j=1:nArms
    avgServer(j,:)=mean(perServer(:,:,j),1);
end
report=struct('names',{ {scenarios.name} }, ...
    'seeds',seeds(:),'perServerUtilization',perServer, ...
    'meanServerUtilization',avgServer, ...
    'utilizationSpread',utilizationSpread, ...
    'strandedTimeFraction',strandedTimeFraction, ...
    'meanLineQueues',perLineMean, ...
    'note','Spread is sample standard deviation across heterogeneous servers, not across replications.');
end
