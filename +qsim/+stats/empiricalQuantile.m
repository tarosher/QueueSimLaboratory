function value = empiricalQuantile(observations,p)
%EMPIRICALQUANTILE Linear-interpolated sample quantile (Type 7, no toolboxes).
if ~(isnumeric(observations) && isreal(observations) && (isempty(observations) || isvector(observations)))
    error('qsim:InvalidStatistics','observations must be a real numeric vector.');
end
if ~(isnumeric(p) && isscalar(p) && isfinite(p) && p>=0 && p<=1)
    error('qsim:InvalidStatistics','p must lie in [0,1].');
end
x=sort(observations(isfinite(observations)));
n=numel(x);
if n==0, value=NaN; return; end
position=1+(n-1)*p;
i=floor(position);
j=ceil(position);
value=x(i)+(position-i)*(x(j)-x(i));
end
