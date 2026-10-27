%RUN_M5_PERFORMANCE Reproducible workloads, NON-GATING wall-clock baseline.
% Call from the QueueSimLab root with MATLAB R2022b.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
folder=fullfile(root,'outputs','performance');
if ~exist(folder,'dir'), mkdir(folder); end
sizes=[100,300,600];
repetitions=3;
models={'Single node','Four-node DAG'};
labels=cell(numel(models)*numel(sizes),1);
arrivalsCount=zeros(size(labels));
trialCount=zeros(size(labels));
medianWallSeconds=nan(size(labels));
minWallSeconds=nan(size(labels));
completed=zeros(size(labels));
rejected=zeros(size(labels));
row=0;
for m=1:numel(models)
    for k=1:numel(sizes)
        n=sizes(k);
        if m==1
            cfg=qsim.defaultConfig();
            cfg.network.nodes.nServers=2;
        else
            cfg=qsim.network.benchmarkBConfig();
        end
        cfg.source.type='schedule';
        cfg.source.times=(0:n-1)'./0.65;
        cfg.simulation.arrivalHorizon=cfg.source.times(end)+1;
        cfg.simulation.observationHorizon=cfg.simulation.arrivalHorizon;
        cfg.simulation.stopMode='drain';
        cfg.simulation.seed=12024;
        cfg.simulation.maxEntities=max(10000,2*n);
        % One warm-up per workload, not part of timing.
        qsim.run(cfg);
        timings=zeros(repetitions,1);
        for j=1:repetitions
            started=tic;
            result=qsim.run(cfg);
            timings(j)=toc(started);
            assert(result.system.arrived==n,'Unexpected source arrival count.');
            assert(result.system.completed+result.system.rejected==n, ...
                'Source conservation failed.');
        end
        row=row+1;
        labels{row}=models{m}; arrivalsCount(row)=n;
        trialCount(row)=repetitions;
        medianWallSeconds(row)=median(timings);
        minWallSeconds(row)=min(timings);
        completed(row)=result.system.completed;
        rejected(row)=result.system.rejected;
        fprintf('[M5 timing] %-14s n=%4d median=%.4f s\n', ...
            models{m},n,medianWallSeconds(row));
    end
end
summary=table(labels,arrivalsCount,trialCount,medianWallSeconds, ...
    minWallSeconds,completed,rejected, ...
    'VariableNames',{'model','scheduledArrivals','trials','medianWallSeconds', ...
    'minWallSeconds','completed','rejected'});
out=fullfile(folder,'m5_runtime_scaling.csv');
writetable(summary,out);
assert(exist(out,'file')==2 && height(readtable(out))==height(summary), ...
    'Performance export did not roundtrip.');
fprintf('M5 performance data: %s\n',out);
