function result = simulateSingleNode(config,arrivalTimes,serviceTimes)
%SIMULATESINGLENODE M2 DES: pooled or dedicated FIFO queues and finite buffers.
% Single-node only. Time-weighted queue/busy metrics integrate over [0,Tobs].
% A rejected customer is counted as arrived but has no start/departure.
s=config.simulation;
node=config.network.nodes;
n=numel(arrivalTimes);
assert(numel(serviceTimes)==n,'Expected one service requirement per arrival.');
assert(all(serviceTimes(:)>0 & isfinite(serviceTimes(:))),'Invalid service requirements.');
c=node.nServers;
if isfield(node,'serverSpeedMultipliers') && ~isempty(node.serverSpeedMultipliers)
    speeds=node.serverSpeedMultipliers(:)';
else
    speeds=ones(1,c);
end
isPooled=strcmp(node.queueMode,'pooledFIFO');
if isPooled
    nLines=1;
else
    nLines=c;
end
if ~isPooled && strcmp(node.routingPolicy,'shortestExpectedWait')
    estimatedMean=qsim.core.expectedServiceMean(node);
else
    estimatedMean=NaN;
end

serverBusy=zeros(1,c); % entity IDs, 0 = idle
% O(n+c) waiting-list memory, avoiding n-by-c dense matrices.
head=zeros(1,nLines);
tail=zeros(1,nLines);
waitingCounts=zeros(1,nLines);
maxQueueByLine=zeros(1,nLines);
lineArrivals=zeros(1,nLines);
completedByServer=zeros(1,c);
nextEntity=zeros(n,1);
started=nan(n,1);
departed=nan(n,1);
assigned=zeros(n,1);
joinedLine=zeros(n,1);
accepted=false(n,1);
rejectionReason=cell(n,1);
calendar=struct('time',{},'kind',{},'entityId',{},'serverId',{},'sequence',{});
seq=0;
if n>0
    seq=seq+1;
    calendar=qsim.core.pushEvent(calendar,arrivalTimes(1),2,1,0,seq);
end
arrived=0; acceptedCount=0; finished=0; rejectedSystem=0; rejectedWaiting=0;
eventCount=0; lastEvent=0;
prevAreaTime=0; areaQ=0; areaQueueByLine=zeros(1,nLines);
areaBusy=0; areaBusyByServer=zeros(1,c); maxQ=0;

while ~isempty(calendar)
    [event,calendar]=qsim.core.nextEvent(calendar,s.tolerance);
    if strcmp(s.stopMode,'truncate') && event.time>s.observationHorizon+s.tolerance
        break;
    end
    if event.time<lastEvent-s.tolerance
        error('qsim:ClockRegression','Event time moved backwards.');
    end
    t=event.time;
    right=min(t,s.observationHorizon);
    if right>prevAreaTime
        dt=right-prevAreaTime;
        areaQ=areaQ+sum(waitingCounts)*dt;
        areaQueueByLine=areaQueueByLine+waitingCounts*dt;
        currentlyBusy=(serverBusy~=0);
        areaBusyByServer=areaBusyByServer+currentlyBusy*dt;
        areaBusy=areaBusy+sum(currentlyBusy)*dt;
        prevAreaTime=right;
    end
    lastEvent=t;
    eventCount=eventCount+1;
    if eventCount>s.maxEvents
        error('qsim:EventLimit','Exceeded maximum event count.');
    end
    id=event.entityId;

    if event.kind==2 % new arrival
        arrived=arrived+1;
        assert(arrived==id,'Arrival sequence invariant failed.');
        if id<n
            seq=seq+1;
            calendar=qsim.core.pushEvent(calendar,arrivalTimes(id+1),2,id+1,0,seq);
        end
        active=sum(serverBusy~=0);
        queued=sum(waitingCounts);
        if active+queued>=node.maxSystemOccupancy
            rejectedSystem=rejectedSystem+1;
            rejectionReason{id}='systemCapacity';
            continue;
        end
        if isPooled
            free=find(serverBusy==0,1,'first');
            lineId=1;
            wantsToWait=isempty(free);
        else
            lineId=qsim.core.selectServer(node.routingPolicy,serverBusy, ...
                waitingCounts,speeds,estimatedMean);
            free=lineId;
            wantsToWait=(serverBusy(lineId)~=0);
        end
        if wantsToWait && queued>=node.maxWaiting
            rejectedWaiting=rejectedWaiting+1;
            rejectionReason{id}='waitingCapacity';
            continue;
        end
        accepted(id)=true;
        acceptedCount=acceptedCount+1;
        joinedLine(id)=lineId;
        lineArrivals(lineId)=lineArrivals(lineId)+1;
        if wantsToWait
            if head(lineId)==0
                head(lineId)=id;
            else
                nextEntity(tail(lineId))=id;
            end
            tail(lineId)=id;
            waitingCounts(lineId)=waitingCounts(lineId)+1;
            maxQueueByLine(lineId)=max(maxQueueByLine(lineId),waitingCounts(lineId));
            maxQ=max(maxQ,sum(waitingCounts));
        else
            started(id)=t;
            assigned(id)=free;
            serverBusy(free)=id;
            seq=seq+1;
            calendar=qsim.core.pushEvent(calendar, ...
                t+serviceTimes(id)/speeds(free),1,id,free,seq);
        end
    elseif event.kind==1 % service completed
        srv=event.serverId;
        assert(serverBusy(srv)==id,'Departure ownership invariant failed.');
        departed(id)=t;
        completedByServer(srv)=completedByServer(srv)+1;
        finished=finished+1;
        serverBusy(srv)=0;
        if isPooled
            lineId=1;
        else
            lineId=srv;
        end
        if head(lineId)~=0
            nextId=head(lineId);
            head(lineId)=nextEntity(nextId);
            if head(lineId)==0
                tail(lineId)=0;
            end
            nextEntity(nextId)=0;
            waitingCounts(lineId)=waitingCounts(lineId)-1;
            assert(waitingCounts(lineId)>=0,'Negative queue length.');
            started(nextId)=t;
            assigned(nextId)=srv;
            serverBusy(srv)=nextId;
            seq=seq+1;
            calendar=qsim.core.pushEvent(calendar, ...
                t+serviceTimes(nextId)/speeds(srv),1,nextId,srv,seq);
        end
    else
        error('qsim:UnexpectedEvent','Unexpected event type.');
    end
    assert(all(waitingCounts>=0),'Negative queue length.');
end
if prevAreaTime<s.observationHorizon
    dt=s.observationHorizon-prevAreaTime;
    areaQ=areaQ+sum(waitingCounts)*dt;
    areaQueueByLine=areaQueueByLine+waitingCounts*dt;
    currentlyBusy=(serverBusy~=0);
    areaBusyByServer=areaBusyByServer+currentlyBusy*dt;
    areaBusy=areaBusy+sum(currentlyBusy)*dt;
end
rejected=rejectedSystem+rejectedWaiting;
backlog=acceptedCount-finished;
assert(arrived==finished+rejected+backlog,'Population conservation failed.');
assert(backlog==sum(waitingCounts)+sum(serverBusy~=0),'Queue occupancy conservation failed.');
assert(sum(lineArrivals)==acceptedCount,'Line assignments must count every accepted entity.');
assert(abs(areaQ-sum(areaQueueByLine))<1e-7*max(1,areaQ), ...
    'Per-line queue areas must sum to global queue area.');
if strcmp(s.stopMode,'drain')
    assert(backlog==0,'Drain left accepted entities unfinished.');
    assert(arrived==n,'Drain left generated entities unprocessed.');
end
wait=started-arrivalTimes(:);
sojourn=departed-arrivalTimes(:);
observedWait=wait(~isnan(wait));
observedSojourn=sojourn(~isnan(sojourn));
if isempty(observedWait), meanWait=NaN; else, meanWait=mean(observedWait); end
if isempty(observedSojourn), meanSojourn=NaN; else, meanSojourn=mean(observedSojourn); end
res=struct('arrived',arrived,'accepted',acceptedCount,'completed',finished, ...
    'rejected',rejected,'rejectedSystemCapacity',rejectedSystem, ...
    'rejectedWaitingCapacity',rejectedWaiting,'backlog',backlog,'generated',n, ...
    'lastEventTime',lastEvent,'meanWaitStartedCohort',meanWait, ...
    'meanSojournCompletedCohort',meanSojourn, ...
    'waitObservedCount',numel(observedWait), ...
    'sojournObservedCount',numel(observedSojourn), ...
    'meanQueueLength',areaQ/s.observationHorizon, ...
    'meanServerUtilization',areaBusy/(s.observationHorizon*c), ...
    'perServerUtilization',areaBusyByServer/s.observationHorizon, ...
    'meanQueueLengthByLine',areaQueueByLine/s.observationHorizon, ...
    'maxQueueByLine',maxQueueByLine, ...
    'acceptedByLine',lineArrivals,'completedByServer',completedByServer, ...
    'totalQueueArea',areaQ,'totalBusyArea',areaBusy, ...
    'maxQueue',maxQ,'eventCount',eventCount);
result=struct();
result.system=res;
result.nodes=struct('id',node.id,'queueMode',node.queueMode, ...
    'arrived',arrived,'accepted',acceptedCount,'completed',finished, ...
    'rejected',rejected,'meanQueueLength',res.meanQueueLength, ...
    'meanServerUtilization',res.meanServerUtilization, ...
    'perServerUtilization',res.perServerUtilization, ...
    'meanQueueLengthByLine',res.meanQueueLengthByLine, ...
    'acceptedByLine',res.acceptedByLine);
if config.output.retainEntityRecords
    result.entities=struct('id',(1:n)','arrivals',arrivalTimes(:), ...
        'serviceRequirements',serviceTimes(:),'startService',started, ...
        'departure',departed,'server',assigned,'line',joinedLine, ...
        'accepted',accepted,'rejectionReason',{rejectionReason}, ...
        'wait',wait,'sojourn',sojourn);
else
    result.entities=[];
end
result.reproducibility=struct('seed',s.seed,'randomness',config.randomness.method, ...
    'stopMode',s.stopMode,'arrivalHorizon',s.arrivalHorizon, ...
    'observationHorizon',s.observationHorizon,'configVersion',config.version);
end
