function out=tagDemandLevels(nodeTables,arrivalRates)
%TAGDEMANDLEVELS Stack node diagnostics and attach scalar demand per row.
% Different topologies and demand levels may contribute different row counts.
% Compatible with MATLAB R2022b; one demandLevel and arrivalRatePerMin per row.
if ~iscell(nodeTables) || isempty(nodeTables) || ...
        ~isnumeric(arrivalRates) || ~isvector(arrivalRates) || ...
        numel(nodeTables)~=numel(arrivalRates) || ...
        any(~isfinite(arrivalRates(:))) || any(arrivalRates(:)<0)
    error('qsim:InvalidExperiment', ...
        'Provide one finite nonnegative arrival rate per node table.');
end
arrivalRates=arrivalRates(:);
for k=1:numel(nodeTables)
    t=nodeTables{k};
    if ~istable(t)
        error('qsim:InvalidExperiment','Each demand-level diagnostic must be a table.');
    end
    if k>1 && ~isequal(t.Properties.VariableNames, ...
            nodeTables{1}.Properties.VariableNames)
        error('qsim:InvalidExperiment', ...
            'All node diagnostic tables must have matching column names.');
    end
    n=height(t);
    t.demandLevel=repmat(k,n,1);
    t.arrivalRatePerMin=repmat(arrivalRates(k),n,1);
    if k==1
        out=t;
    else
        out=[out; t]; %#ok<AGROW>
    end
end
end
