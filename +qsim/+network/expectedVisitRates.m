function rates=expectedVisitRates(config,externalRate)
%EXPECTEDVISITRATES Solve open-network traffic equations for expected visits.
%   lambda = gamma + P' * lambda  => (I-P') * lambda = gamma.
%   This is a routing-flow check, not a service waiting-time prediction.
qsim.validateConfig(config);
if ~config.extensions.network
    error('qsim:InvalidNetwork','Expected visit rates require network mode.');
end
if nargin<2
    if ~strcmp(config.source.type,'poisson')
        error('qsim:InvalidNetwork', ...
            'Supply an explicit external arrival rate for non-Poisson sources.');
    end
    externalRate=config.source.rate;
end
if ~isnumeric(externalRate) || ~isscalar(externalRate) || ...
        ~isreal(externalRate) || ~isfinite(externalRate) || externalRate<0
    error('qsim:InvalidNetwork','External arrival rate must be nonnegative finite.');
end
ids={config.network.nodes.id};
V=numel(ids);
P=zeros(V,V);
for k=1:numel(config.network.links)
    lk=config.network.links(k);
    a=find(strcmp(ids,lk.from),1);
    b=find(strcmp(ids,lk.to),1);
    P(a,b)=P(a,b)+lk.probability;
end
entry=1;
if isfield(config.source,'entryNode') && ~isempty(config.source.entryNode)
    entry=find(strcmp(ids,config.source.entryNode),1);
end
gamma=zeros(V,1);
gamma(entry)=externalRate;
lambda=(eye(V)-P')\gamma;
if any(lambda < -1e-9) || any(~isfinite(lambda))
    error('qsim:NetworkInvariant','Invalid network flow solution.');
end
lambda=max(0,lambda);
exitRates=lambda.*max(0,1-sum(P,2));
rates=struct('nodeIds',{ids},'external',gamma, ...
    'transitionMatrix',P,'nodeRates',lambda, ...
    'exitRates',exitRates,'totalExitRate',sum(exitRates));
end
