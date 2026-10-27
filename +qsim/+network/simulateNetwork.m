function result=simulateNetwork(config,arrivalTimes)
%SIMULATENETWORK Event-driven open DAG of FIFO service nodes, base MATLAB.
% M4: tandem, branch and merge; outgoing probability deficit exits network.
% A rejection at any node removes that entity (no upstream backpressure).
% Each source entity visits any node at most once because graph is acyclic.
% Service requirements are assigned by source entity AND node before routing,
% keeping exogenous workload independent of queue decisions/server allocation.
s=config.simulation;
nodes=config.network.nodes;
links=config.network.links;
N=numel(arrivalTimes);
V=numel(nodes);
nodeIds={nodes.id};
if isfield(config.source,'entryNode') && ~isempty(config.source.entryNode)
    entry=find(strcmp(nodeIds,config.source.entryNode),1);
else
    entry=1;
end
work=zeros(N,V);
for v=1:V
    work(:,v)=qsim.sources.generateServices(nodes(v).serviceDistribution,N);
end
routeUniform=rand(N,V); % independent of service allocation and route calls
linkFrom=zeros(1,numel(links));
linkTo=zeros(1,numel(links));
for k=1:numel(links)
    linkFrom(k)=find(strcmp(nodeIds,links(k).from),1);
    linkTo(k)=find(strcmp(nodeIds,links(k).to),1);
end
linkCount=zeros(1,numel(links));
sinkCount=zeros(1,V);

blank=struct('serverBusy',[],'speeds',[],'heads',[],'tails',[], ...
    'waitingCounts',[],'queueAreaByLine',[],'busyAreaByServer',[], ...
    'maxQueueByLine',[],'maxQueue',0,'arrived',0,'accepted',0, ...
    'completed',0,'rejected',0,'rejectedSystemCapacity',0, ...
    'rejectedWaitingCapacity',0,'acceptedByLine',[], ...
    'completedByServer',[],'estimatedMean',NaN);
states=repmat(blank,1,V);
for v=1:V
    c=nodes(v).nServers;
    if isempty(nodes(v).serverSpeedMultipliers)
        speeds=ones(1,c);
    else
        speeds=nodes(v).serverSpeedMultipliers(:)';
    end
    if strcmp(nodes(v).queueMode,'pooledFIFO'), nLines=1; else, nLines=c; end
    states(v).serverBusy=zeros(1,c); % currently serving visit ID
    states(v).speeds=speeds;
    states(v).heads=zeros(1,nLines);
    states(v).tails=zeros(1,nLines);
    states(v).waitingCounts=zeros(1,nLines);
    states(v).queueAreaByLine=zeros(1,nLines);
    states(v).busyAreaByServer=zeros(1,c);
    states(v).maxQueueByLine=zeros(1,nLines);
    states(v).acceptedByLine=zeros(1,nLines);
    states(v).completedByServer=zeros(1,c);
    if strcmp(nodes(v).queueMode,'separateFIFO') && ...
            strcmp(nodes(v).routingPolicy,'shortestExpectedWait')
        states(v).estimatedMean=qsim.core.expectedServiceMean(nodes(v));
    end
end
visitTemplate=struct('id',0,'entityId',0,'nodeId','','nodeIndex',0, ...
    'fromNode','','arrival',NaN,'startService',NaN,'departure',NaN, ...
    'serviceRequirements',NaN,'wait',NaN,'sojourn',NaN, ...
    'server',0,'line',0,'accepted',false,'rejectionReason','', ...
    'nextNode','');
visits=repmat(visitTemplate,0,1);
nextVisit=zeros(0,1);
status=zeros(N,1); % 0 not introduced, 1 active, 2 exited, 3 rejected
entryAccepted=false(N,1);
entityExit=nan(N,1);
entityWait=nan(N,1);
entityRejectNode=cell(N,1);
entityRejectReason=cell(N,1);
calendar=struct('time',{},'kind',{},'entityId',{},'serverId',{}, ...
    'sequence',{},'nodeIndex',{},'visitId',{},'isExternal',{},'fromIndex',{});
sequence=0;
if N>0, addEvent(arrivalTimes(1),2,1,0,entry,0,true,0); end
sourceProcessed=0;
prevArea=0;
lastTime=0;
eventCount=0;

while ~isempty(calendar)
    [e,calendar]=qsim.core.nextEvent(calendar,s.tolerance);
    if strcmp(s.stopMode,'truncate') && e.time>s.observationHorizon+s.tolerance
        break;
    end
    if e.time<lastTime-s.tolerance
        error('qsim:ClockRegression','Network clock moved backwards.');
    end
    t=e.time;
    integrateAreas(min(t,s.observationHorizon));
    lastTime=t;
    eventCount=eventCount+1;
    if eventCount>s.maxEvents
        error('qsim:EventLimit','Exceeded network maxEvents.');
    end
    if e.kind==2 % external arrival or downstream transfer
        id=e.entityId;
        if e.isExternal
            sourceProcessed=sourceProcessed+1;
            if id~=sourceProcessed
                error('qsim:NetworkInvariant','External arrival IDs out of order.');
            end
            status(id)=1;
            if id<N
                addEvent(arrivalTimes(id+1),2,id+1,0,entry,0,true,0);
            end
        end
        nodeArrival(id,e.nodeIndex,e.fromIndex,t,e.isExternal);
    elseif e.kind==1
        completeService(e.visitId,e.nodeIndex,e.serverId,t);
    else
        error('qsim:UnexpectedEvent','Unexpected network event type.');
    end
end
integrateAreas(s.observationHorizon);
exited=sum(status==2);
lost=sum(status==3);
backlog=sum(status==1);
if sourceProcessed~=exited+lost+backlog
    error('qsim:NetworkInvariant','Source conservation violated.');
end
if strcmp(s.stopMode,'drain') && (sourceProcessed~=N || backlog~=0)
    error('qsim:NetworkInvariant','Drain left unprocessed entities.');
end
nodeResults=repmat(struct('id','','queueMode','','nServers',0, ...
    'arrived',0,'accepted',0,'completed',0,'rejected',0, ...
    'rejectedSystemCapacity',0,'rejectedWaitingCapacity',0, ...
    'meanWaitStartedCohort',NaN,'meanSojournCompletedCohort',NaN, ...
    'meanQueueLength',0,'meanServerUtilization',0, ...
    'meanQueueLengthByLine',[],'perServerUtilization',[], ...
    'acceptedByLine',[],'completedByServer',[],'maxQueue',0, ...
    'maxQueueByLine',[],'totalQueueArea',0,'totalBusyArea',0, ...
    'throughputObserved',0),1,V);
totalQueueArea=0;
totalBusyArea=0;
totalServers=0;
for v=1:V
    st=states(v);
    % At cutoff, queued + busy equals accepted visits still at this node.
    pending=st.accepted-st.completed;
    actual=sum(st.waitingCounts)+sum(st.serverBusy~=0);
    if strcmp(s.stopMode,'drain') && pending~=0
        error('qsim:NetworkInvariant','Node was not drained.');
    end
    if pending~=actual
        error('qsim:NetworkInvariant','Node occupancy conservation violated.');
    end
    ix=find([visits.nodeIndex]==v);
    wait=[]; sojourn=[]; departures=[];
    if ~isempty(ix)
        w=[visits(ix).wait]; wait=w(isfinite(w));
        w=[visits(ix).sojourn]; sojourn=w(isfinite(w));
        departures=[visits(ix).departure];
    end
    nodeResults(v).id=nodeIds{v};
    nodeResults(v).queueMode=nodes(v).queueMode;
    nodeResults(v).nServers=nodes(v).nServers;
    nodeResults(v).arrived=st.arrived;
    nodeResults(v).accepted=st.accepted;
    nodeResults(v).completed=st.completed;
    nodeResults(v).rejected=st.rejected;
    nodeResults(v).rejectedSystemCapacity=st.rejectedSystemCapacity;
    nodeResults(v).rejectedWaitingCapacity=st.rejectedWaitingCapacity;
    if ~isempty(wait), nodeResults(v).meanWaitStartedCohort=mean(wait); end
    if ~isempty(sojourn), nodeResults(v).meanSojournCompletedCohort=mean(sojourn); end
    nodeResults(v).meanQueueLengthByLine=st.queueAreaByLine/s.observationHorizon;
    nodeResults(v).meanQueueLength=sum(st.queueAreaByLine)/s.observationHorizon;
    nodeResults(v).perServerUtilization=st.busyAreaByServer/s.observationHorizon;
    nodeResults(v).meanServerUtilization=mean(nodeResults(v).perServerUtilization);
    nodeResults(v).acceptedByLine=st.acceptedByLine;
    nodeResults(v).completedByServer=st.completedByServer;
    nodeResults(v).maxQueue=st.maxQueue;
    nodeResults(v).maxQueueByLine=st.maxQueueByLine;
    nodeResults(v).totalQueueArea=sum(st.queueAreaByLine);
    nodeResults(v).totalBusyArea=sum(st.busyAreaByServer);
    nodeResults(v).throughputObserved=sum(isfinite(departures) & ...
        departures<=s.observationHorizon)/s.observationHorizon;
    if st.arrived~=st.accepted+st.rejected
        error('qsim:NetworkInvariant','Node admissions do not balance.');
    end
    totalQueueArea=totalQueueArea+nodeResults(v).totalQueueArea;
    totalBusyArea=totalBusyArea+nodeResults(v).totalBusyArea;
    totalServers=totalServers+nodes(v).nServers;
end
soj=entityExit-arrivalTimes(:);
validSoj=soj(isfinite(soj));
entityCompleteWait=entityWait(status==2);
if isempty(validSoj), meanSoj=NaN; else, meanSoj=mean(validSoj); end
if isempty(entityCompleteWait), meanWait=NaN; else, meanWait=mean(entityCompleteWait); end
system=struct('generated',N,'arrived',sourceProcessed, ...
    'accepted',sum(entryAccepted),'completed',exited,'rejected',lost, ...
    'backlog',backlog,'meanEndToEndSojournCompletedCohort',meanSoj, ...
    'meanTotalWaitCompletedCohort',meanWait, ...
    'meanQueueLength',totalQueueArea/s.observationHorizon, ...
    'meanServerUtilization',totalBusyArea/(s.observationHorizon*totalServers), ...
    'throughputObserved',sum(isfinite(entityExit) & ...
        entityExit<=s.observationHorizon)/s.observationHorizon, ...
    'eventCount',eventCount,'lastEventTime',lastTime, ...
    'totalVisits',numel(visits),'totalQueueArea',totalQueueArea, ...
    'totalBusyArea',totalBusyArea);
result=struct();
result.system=system;
result.nodes=nodeResults;
result.network=struct();
result.network.nodeIds=nodeIds;
result.network.links=links;
result.network.linkTraversalCounts=linkCount;
result.network.sinkExitsByNode=sinkCount;
result.network.entryNode=nodeIds{entry};
if config.output.retainEntityRecords
    result.entities=struct('id',(1:N)','arrivals',arrivalTimes(:), ...
        'accepted',entryAccepted,'departure',entityExit, ...
        'rejected',status==3,'rejectionNode',{entityRejectNode}, ...
        'rejectionReason',{entityRejectReason},'wait',entityWait, ...
        'sojourn',soj,'status',status);
    result.visits=visits;
else
    result.entities=[];
    result.visits=[];
end
result.reproducibility=struct('seed',s.seed, ...
    'randomness',config.randomness.method,'stopMode',s.stopMode, ...
    'arrivalHorizon',s.arrivalHorizon, ...
    'observationHorizon',s.observationHorizon, ...
    'configVersion',config.version,'networkMode','M4-DAG');

    function addEvent(time,kind,entity,server,v,visitId,isExternal,from)
        sequence=sequence+1;
        event=struct('time',time,'kind',kind,'entityId',entity, ...
            'serverId',server,'sequence',sequence,'nodeIndex',v, ...
            'visitId',visitId,'isExternal',isExternal,'fromIndex',from);
        calendar(end+1)=event;
    end

    function integrateAreas(right)
        if right<=prevArea, return; end
        dt=right-prevArea;
        for j=1:V
            states(j).queueAreaByLine=states(j).queueAreaByLine+ ...
                states(j).waitingCounts*dt;
            states(j).busyAreaByServer=states(j).busyAreaByServer+ ...
                (states(j).serverBusy~=0)*dt;
        end
        prevArea=right;
    end

    function nodeArrival(id,v,from,t,isExternal)
        st=states(v);
        st.arrived=st.arrived+1;
        visitId=numel(visits)+1;
        rec=visitTemplate;
        rec.id=visitId;
        rec.entityId=id;
        rec.nodeId=nodeIds{v};
        rec.nodeIndex=v;
        if from==0, rec.fromNode='SOURCE'; else, rec.fromNode=nodeIds{from}; end
        rec.arrival=t;
        rec.serviceRequirements=work(id,v);
        visits(visitId,1)=rec;
        nextVisit(visitId,1)=0;
        occupied=sum(st.waitingCounts)+sum(st.serverBusy~=0);
        reason='';
        if occupied>=nodes(v).maxSystemOccupancy
            reason='systemCapacity';
            st.rejectedSystemCapacity=st.rejectedSystemCapacity+1;
        else
            if strcmp(nodes(v).queueMode,'pooledFIFO')
                line=1;
                server=find(st.serverBusy==0,1,'first');
                mustWait=isempty(server);
            else
                line=qsim.core.selectServer(nodes(v).routingPolicy, ...
                    st.serverBusy,st.waitingCounts,st.speeds,st.estimatedMean);
                server=line;
                mustWait=st.serverBusy(server)~=0;
            end
            if mustWait && sum(st.waitingCounts)>=nodes(v).maxWaiting
                reason='waitingCapacity';
                st.rejectedWaitingCapacity=st.rejectedWaitingCapacity+1;
            end
        end
        if ~isempty(reason)
            st.rejected=st.rejected+1;
            visits(visitId).rejectionReason=reason;
            entityRejectNode{id}=nodeIds{v};
            entityRejectReason{id}=reason;
            status(id)=3;
        else
            st.accepted=st.accepted+1;
            st.acceptedByLine(line)=st.acceptedByLine(line)+1;
            visits(visitId).accepted=true;
            visits(visitId).line=line;
            if isExternal
                entryAccepted(id)=true;
                entityWait(id)=0;
            end
            if mustWait
                if st.heads(line)==0
                    st.heads(line)=visitId;
                else
                    nextVisit(st.tails(line))=visitId;
                end
                st.tails(line)=visitId;
                st.waitingCounts(line)=st.waitingCounts(line)+1;
                st.maxQueueByLine(line)=max(st.maxQueueByLine(line), ...
                    st.waitingCounts(line));
                st.maxQueue=max(st.maxQueue,sum(st.waitingCounts));
            else
                states(v)=st;
                startService(visitId,v,server,t);
                return;
            end
        end
        states(v)=st;
    end

    function startService(visitId,v,server,t)
        id=visits(visitId).entityId;
        if states(v).serverBusy(server)~=0
            error('qsim:NetworkInvariant','Double-booked server.');
        end
        visits(visitId).startService=t;
        visits(visitId).server=server;
        visits(visitId).wait=t-visits(visitId).arrival;
        entityWait(id)=entityWait(id)+visits(visitId).wait;
        states(v).serverBusy(server)=visitId;
        serviceTime=work(id,v)/states(v).speeds(server);
        addEvent(t+serviceTime,1,id,server,v,visitId,false,0);
    end

    function completeService(visitId,v,server,t)
        st=states(v);
        if st.serverBusy(server)~=visitId
            error('qsim:NetworkInvariant','Completion does not own server.');
        end
        st.serverBusy(server)=0;
        st.completed=st.completed+1;
        st.completedByServer(server)=st.completedByServer(server)+1;
        visits(visitId).departure=t;
        visits(visitId).sojourn=t-visits(visitId).arrival;
        if strcmp(nodes(v).queueMode,'pooledFIFO'), line=1; else, line=server; end
        if st.heads(line)~=0
            nextId=st.heads(line);
            st.heads(line)=nextVisit(nextId);
            if st.heads(line)==0, st.tails(line)=0; end
            nextVisit(nextId)=0;
            st.waitingCounts(line)=st.waitingCounts(line)-1;
            states(v)=st;
            startService(nextId,v,server,t);
        else
            states(v)=st;
        end
        id=visits(visitId).entityId;
        outgoing=find(linkFrom==v);
        choice=routeUniform(id,v);
        selected=0;
        cum=0;
        for k=outgoing
            cum=cum+links(k).probability;
            if choice<cum
                selected=k;
                break;
            end
        end
        if selected==0
            status(id)=2;
            entityExit(id)=t;
            sinkCount(v)=sinkCount(v)+1;
            visits(visitId).nextNode='SINK';
        else
            nextNode=linkTo(selected);
            visits(visitId).nextNode=nodeIds{nextNode};
            linkCount(selected)=linkCount(selected)+1;
            addEvent(t+links(selected).delay,2,id,0,nextNode,0,false,v);
        end
    end
end
