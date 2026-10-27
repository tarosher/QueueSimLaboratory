function rows = pairwiseMeanWait(result)
%PAIRWISEMEANWAIT All pairwise mean-Wq comparisons using replication pairs.
% Differences are second scenario minus first scenario (B-A).
names={result.summary.name};
n=numel(names);
rows=repmat(struct('scenarioA','','scenarioB','','ci',struct()),n*(n-1)/2,1);
k=0;
for i=1:n
    for j=i+1:n
        k=k+1;
        rows(k).scenarioA=names{i};
        rows(k).scenarioB=names{j};
        values=result.raw.meanWait(:,j)-result.raw.meanWait(:,i);
        rows(k).ci=qsim.stats.meanCI(values,result.options.confidence);
    end
end
end
