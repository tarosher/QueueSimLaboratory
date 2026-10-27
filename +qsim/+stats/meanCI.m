function out = meanCI(values, confidence)
%MEANCI Two-sided Student-t CI for a replication-level mean (base MATLAB).
% Nonfinite replications are excluded AND counted in nMissing; n<2 => no CI.
% Replications, not individual customer observations, are the statistical units.
if nargin<2, confidence=0.95; end
if ~(isnumeric(values) && isreal(values) && (isempty(values) || isvector(values)))
    error('qsim:InvalidStatistics','values must be a real numeric vector.');
end
if ~(isnumeric(confidence) && isscalar(confidence) && isfinite(confidence) && ...
        confidence>0 && confidence<1)
    error('qsim:InvalidStatistics','confidence must be strictly between 0 and 1.');
end
values=values(:);
valid=values(isfinite(values));
n=numel(valid);
out=struct('mean',NaN,'lower',NaN,'upper',NaN,'halfWidth',NaN, ...
    'std',NaN,'nValid',n,'nMissing',numel(values)-n,'confidence',confidence);
if n==0, return; end
out.mean=mean(valid);
if n==1, return; end
out.std=std(valid,0);
if out.std==0
    halfWidth=0;
else
    % For t_{df}, P(T > t)=0.5*betainc(df/(df+t^2),df/2,1/2).
    % betaincinv is available in base MATLAB; no Statistics Toolbox / tinv.
    df=n-1;
    z=betaincinv(1-confidence,df/2,0.5);
    critical=sqrt(df*(1-z)/z);
    halfWidth=critical*out.std/sqrt(n);
end
out.halfWidth=halfWidth;
out.lower=out.mean-halfWidth;
out.upper=out.mean+halfWidth;
end
