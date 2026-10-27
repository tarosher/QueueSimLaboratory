function services = generateServices(distribution,n)
%GENERATESERVICES Preassign per-entity base work independent of queue policy.
if strcmp(distribution.type,'sequence')
    assert(numel(distribution.values)>=n, ...
        'Service sequence must contain >= n arrival-cohort entries.');
    services=distribution.values(1:n);
    services=services(:);
else
    services=qsim.sources.sampleDuration(distribution,n);
end
assert(all(isfinite(services(:)) & services(:)>0), ...
    'Service requirements must be finite and positive.');
end
