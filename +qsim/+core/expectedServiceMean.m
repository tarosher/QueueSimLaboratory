function m=expectedServiceMean(node)
%EXPECTEDSERVICEMEAN Public workload estimate used by shortestExpectedWait.
if isfield(node,'routingServiceMean') && isnumeric(node.routingServiceMean) && ...
        isscalar(node.routingServiceMean) && isfinite(node.routingServiceMean)
    m=node.routingServiceMean;
    return;
end
d=node.serviceDistribution;
switch d.type
    case 'exponential'
        m=1/d.rate;
    case 'deterministic'
        m=d.value;
    case 'uniform'
        m=(d.min+d.max)/2;
    case 'lognormal'
        m=exp(d.muLog+0.5*d.sigmaLog^2);
    case 'sequence'
        error('qsim:RoutingMean', ...
            'Sequence service needs explicit routingServiceMean; future durations are not observable.');
    otherwise
        error('qsim:RoutingMean','Unknown service distribution.');
end
assert(isfinite(m) && m>0,'Specify a finite positive routingServiceMean.');
end
