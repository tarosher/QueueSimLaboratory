function [x,f] = empiricalCDF(values)
%EMPIRICALCDF Empirical waiting-time CDF without Statistics Toolbox.
values=values(isfinite(values));
values=sort(values(:));
if isempty(values)
    x=[]; f=[];
    return;
end
[x,~,group]=unique(values);
counts=accumarray(group,1,[numel(x),1]);
f=cumsum(counts)/numel(values);
end
