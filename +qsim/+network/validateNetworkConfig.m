function validateNetworkConfig(c)
%VALIDATENETWORKCONFIG M4 DAG routing layer; reuses validated M2 node rules.
% Only true multi-node networks opt into this layer. All time units: minutes.
if ~isstruct(c) || ~isscalar(c) || ~isfield(c,'extensions') || ...
        ~isfield(c.extensions,'network') || ~isequal(c.extensions.network,true)
    error('qsim:InvalidNetwork','A network configuration requires extensions.network=true.');
end
if ~isfield(c,'network') || ~isfield(c.network,'nodes') || ...
        ~isstruct(c.network.nodes) || numel(c.network.nodes)<2
    error('qsim:UnsupportedExtension','M4 network mode requires at least two service nodes.');
end
nodes=c.network.nodes;
n=numel(nodes);
ids=cell(1,n);
for i=1:n
    ids{i}=nodes(i).id;
    % Delegate all M2 model and simulation checks to the already accepted
    % validator. Do not allow unrelated reserved extensions to slip through.
    single=c;
    single.extensions.network=false;
    single.network.nodes=nodes(i);
    single.network.links=[];
    qsim.validateConfig(single);
end
if numel(unique(ids))~=n
    error('qsim:InvalidNetwork','Node IDs must be unique.');
end
if ~isfield(c.source,'entryNode') || isempty(c.source.entryNode)
    entry=ids{1};
else
    entry=c.source.entryNode;
end
if ~ischar(entry) || ~any(strcmp(ids,entry))
    error('qsim:InvalidNetwork','source.entryNode must match an existing node ID.');
end
links=c.network.links;
if isempty(links)
    links=struct('from',{},'to',{},'probability',{},'delay',{});
elseif ~isstruct(links)
    error('qsim:InvalidNetwork','network.links must be a struct array.');
end
adj=false(n,n);
sumP=zeros(1,n);
for k=1:numel(links)
    link=links(k);
    fields={'from','to','probability','delay'};
    for j=1:numel(fields)
        if ~isfield(link,fields{j})
            error('qsim:InvalidNetwork','Each link requires from/to/probability/delay.');
        end
    end
    if ~ischar(link.from) || ~ischar(link.to)
        error('qsim:InvalidNetwork','Link endpoints must be char IDs.');
    end
    a=find(strcmp(ids,link.from),1);
    b=find(strcmp(ids,link.to),1);
    if isempty(a) || isempty(b) || a==b
        error('qsim:InvalidNetwork','Links must reference distinct existing nodes.');
    end
    if adj(a,b)
        error('qsim:InvalidNetwork','Duplicate directed links are not supported.');
    end
    if ~isnumeric(link.probability) || ~isscalar(link.probability) || ...
            ~isreal(link.probability) || ~isfinite(link.probability) || ...
            link.probability<=0 || link.probability>1
        error('qsim:InvalidNetwork','Link probability must be in (0,1].');
    end
    if ~isnumeric(link.delay) || ~isscalar(link.delay) || ...
            ~isreal(link.delay) || ~isfinite(link.delay) || link.delay<0
        error('qsim:InvalidNetwork','Transfer delay must be nonnegative finite minutes.');
    end
    sumP(a)=sumP(a)+link.probability;
    adj(a,b)=true;
end
if any(sumP>1+1e-12)
    error('qsim:InvalidNetwork','Outgoing link probabilities exceed one.');
end
% Kahn topological order: no cyclic routes, feedback, or fork/join in M4.
inDegree=sum(adj,1);
ready=find(inDegree==0);
seen=0;
while ~isempty(ready)
    u=ready(1); ready(1)=[];
    seen=seen+1;
    children=find(adj(u,:));
    for j=1:numel(children)
        v=children(j);
        inDegree(v)=inDegree(v)-1;
        if inDegree(v)==0, ready(end+1)=v; end %#ok<AGROW>
    end
end
if seen~=n
    error('qsim:InvalidNetwork','M4 requires a directed acyclic queueing network.');
end
end
