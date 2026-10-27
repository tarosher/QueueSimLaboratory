function draws=sampleDuration(d,n)
%SAMPLEDURATION Basic-MATLAB positive duration draws (minutes).
switch d.type
    case 'exponential'
        draws=-log(max(realmin,rand(n,1)))/d.rate;
    case 'deterministic'
        draws=repmat(d.value,n,1);
    case 'uniform'
        draws=d.min+(d.max-d.min).*rand(n,1);
    case 'lognormal'
        draws=exp(d.muLog+d.sigmaLog.*randn(n,1));
    otherwise
        error('qsim:DurationType','Unsupported duration distribution %s.',d.type);
end
assert(all(isfinite(draws(:)) & draws(:)>0),'Generated duration must be finite and positive.');
end
