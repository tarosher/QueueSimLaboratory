function server=selectServer(policy,serverBusy,waitingCounts,speeds,estimatedMean)
%SELECTSERVER Route entity to one dedicated FIFO lane. No future-work oracle.
c=numel(serverBusy);
switch policy
    case 'random'
        server=randi(c);
    case 'shortestQueue'
        % The line includes its currently serviced entity.
        counts=waitingCounts(:)' + (serverBusy(:)'~=0);
        [~,server]=min(counts);  % deterministic lowest-index tie
    case 'shortestExpectedWait'
        % Public distributional mean only, not individual future service draws.
        % Each existing job contributes expected remaining work. The score
        % is measured in *estimated minutes* and respects server speeds.
        nAhead=waitingCounts(:)' + (serverBusy(:)'~=0);
        scores=nAhead.*estimatedMean./speeds(:)';
        [~,server]=min(scores);
    otherwise
        error('qsim:RoutingPolicy','Unsupported routing policy %s.',policy);
end
end
