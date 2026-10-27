function arrivals = generateArrivals(source,horizon,maxEntities,tol)
%GENERATEARRIVALS Generate scheduled, Poisson or renewal arrivals.
% Returns column vector; positive renewal interarrival draws avoid zero-time loops.
if strcmp(source.type,'schedule')
    arrivals=source.times(:);
    assert(numel(arrivals)<=maxEntities,'Entity count exceeds maxEntities.');
    return;
end
if strcmp(source.type,'poisson') && source.rate==0
    arrivals=zeros(0,1);
    return;
end
arrivals=zeros(0,1);
t=0;
while true
    if strcmp(source.type,'poisson')
        gap=-log(max(realmin,rand()))/source.rate;
    else
        gap=qsim.sources.sampleDuration(source.interarrivalDistribution,1);
    end
    assert(isfinite(gap) && gap>0,'Arrival increment must be finite and positive.');
    t=t+gap;
    if t>horizon+tol
        break;
    end
    if numel(arrivals)>=maxEntities
        error('qsim:EntityLimit','Exceeded maxEntities: adjust limit or arrival process.');
    end
    arrivals(end+1,1)=t; %#ok<AGROW>
end
end
