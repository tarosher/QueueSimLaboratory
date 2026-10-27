function trace = reconstructTrace(result,observationHorizon)
%RECONSTRUCTTRACE Rebuild exact right-continuous queue/busy histories.
% Derives queue and busy transitions from entity arrival/start/departure
% timestamps; does not change the DES engine or its event sequence.
% Only accepted customers contribute to occupancy. Values at exact tied
% timestamps are AFTER all events at that timestamp; integrals therefore
% match time-weighted measures irrespective of event tie order.
if nargin<2 || isempty(observationHorizon)
    observationHorizon=result.reproducibility.observationHorizon;
end
if ~isnumeric(observationHorizon) || ~isscalar(observationHorizon) || ...
        ~isfinite(observationHorizon) || observationHorizon<=0
    error('qsim:InvalidTrace','observationHorizon must be positive finite.');
end
if ~isstruct(result.entities) || isempty(result.entities)
    error('qsim:InvalidTrace','Entity records are required for trace reconstruction.');
end
e=result.entities;
nServers=numel(result.system.perServerUtilization);
nLines=numel(result.system.meanQueueLengthByLine);
accepted=e.accepted(:);
a=e.arrivals(:);
s=e.startService(:);
d=e.departure(:);
line=e.line(:);
server=e.server(:);
if any(accepted & (~isfinite(a) | line<1 | line>nLines))
    error('qsim:InvalidTrace','Inconsistent accepted entity records.');
end
% Append signed transitions and bin same-timestamp events. Events after
% observationHorizon belong to drain and must not affect observed areas.
qa=a(accepted & a<=observationHorizon);
la=line(accepted & a<=observationHorizon);
qs=s(accepted & isfinite(s) & s<=observationHorizon);
ls=line(accepted & isfinite(s) & s<=observationHorizon);
bs=s(accepted & isfinite(s) & s<=observationHorizon);
ss=server(accepted & isfinite(s) & s<=observationHorizon);
bd=d(accepted & isfinite(d) & d<=observationHorizon);
sd=server(accepted & isfinite(d) & d<=observationHorizon);
if any(ss<1 | ss>nServers) || any(sd<1 | sd>nServers)
    error('qsim:InvalidTrace','Inconsistent server assignments.');
end
qTimes=[qa;qs]; qLines=[la;ls]; qDelta=[ones(numel(qa),1);-ones(numel(qs),1)];
bTimes=[bs;bd]; bServers=[ss;sd]; bDelta=[ones(numel(bs),1);-ones(numel(bd),1)];
times=unique([0;observationHorizon;qTimes;bTimes]);
nTimes=numel(times);
queueStep=zeros(nTimes,nLines);
busyStep=zeros(nTimes,nServers);
if ~isempty(qTimes)
    [~,ix]=ismember(qTimes,times);
    queueStep=accumarray([ix,qLines],qDelta,[nTimes,nLines],@sum,0);
end
if ~isempty(bTimes)
    [~,ix]=ismember(bTimes,times);
    busyStep=accumarray([ix,bServers],bDelta,[nTimes,nServers],@sum,0);
end
queueByLine=cumsum(queueStep,1);
busyByServer=cumsum(busyStep,1);
if any(queueByLine(:)<0) || any(busyByServer(:)<0 | busyByServer(:)>1)
    error('qsim:InvalidTrace','Reconstructed queue/server occupancy is invalid.');
end
queueTotal=sum(queueByLine,2);
busyTotal=sum(busyByServer,2);
dt=diff(times);
areaQ=sum(queueTotal(1:end-1).*dt);
areaBusy=sum(busyTotal(1:end-1).*dt);
% A non-work-conserving independent-queue state: someone is waiting while
% at least one server is idle. This cannot occur under pooled FIFO except
% instantaneously at tied events (which have zero time measure).
strandedFraction=sum((queueTotal(1:end-1)>0 & ...
    busyTotal(1:end-1)<nServers).*dt)/observationHorizon;
% Validate exact reconstruction against DES time-weighted accumulators.
qRef=result.system.meanQueueLength*observationHorizon;
bRef=result.system.meanServerUtilization*nServers*observationHorizon;
if abs(areaQ-qRef)>1e-7*max(1,abs(qRef)) || ...
        abs(areaBusy-bRef)>1e-7*max(1,abs(bRef))
    error('qsim:TraceMismatch','Entity-based trace does not match engine time integrals.');
end
trace=struct('time',times,'queueTotal',queueTotal,'busyTotal',busyTotal, ...
    'queueByLine',queueByLine,'busyByServer',busyByServer, ...
    'meanQueueLength',areaQ/observationHorizon, ...
    'meanUtilization',areaBusy/(nServers*observationHorizon), ...
    'strandedTimeFraction',strandedFraction, ...
    'observationHorizon',observationHorizon, ...
    'semantics','Right-continuous state; exact ties aggregated; drain excluded after horizon');
end
