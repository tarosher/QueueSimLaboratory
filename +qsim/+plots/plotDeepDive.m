function files = plotDeepDive(baseline,singleRuns,traces,diagnostics,loadSweep,capacitySweep,folder)
%PLOTDEEPDIVE Four purpose-driven diagnostic charts (MATLAB R2022b).
% Every chart addresses a model question: queue mechanism, wait tails,
% demand sensitivity, or capacity decisions. Original M3 charts stay
% available via plotPolicyBenchmark, without redundant new graphics.
if nargin<7 || isempty(folder)
    folder=fullfile(pwd,'outputs','benchmarkA_deepdive');
end
if ~exist(folder,'dir'), mkdir(folder); end
names={baseline.summary.name};
n=numel(names); colors=lines(n);
files=struct();

% 1. Mechanism: an exact single-run queue trajectory and replicated
% fraction of time customers waited while a server was idle.
f=figure('Visible','off','Color','w','Position',[80 80 1100 720]);
cl=onCleanup(@()closeIfOpen(f)); %#ok<NASGU>
tiledlayout(2,1,'Padding','compact','TileSpacing','compact');
nexttile; hold on;
queueHandles=gobjects(1,n);
for j=1:n
    queueHandles(j)=stairs(traces(j).time,traces(j).queueTotal,'LineWidth',1.15, ...
        'Color',colors(j,:));
end
legend(queueHandles,names,'Location','northwest');
xlabel('Time since start (minutes)'); ylabel('Waiting customers');
window=min(90,traces(1).observationHorizon);
xlim([0,window]); grid on;
title(sprintf('Queue dynamics | first %.0f minutes of ONE matched-seed replication',window));
nexttile; hold on;
for j=1:n
    ci=qsim.stats.meanCI(diagnostics.strandedTimeFraction(:,j),baseline.options.confidence);
    if isfinite(ci.mean)
        errorbar(j,ci.mean,ci.mean-ci.lower,ci.upper-ci.mean,'o', ...
            'Color',colors(j,:),'MarkerFaceColor',colors(j,:), ...
            'MarkerSize',7,'LineWidth',1.6);
    end
end
xticks(1:n); xticklabels(names); xtickangle(10);
xlim([.5,n+.5]); ylim([0,1]); grid on;
ylabel('Fraction of time with idle server AND waiting customers');
title('Capacity stranded by queue organization | 95% replication CI');
files.queueMechanism=saveFig(f,folder,'benchmarkA_queue_mechanism.png');
close(f); clear cl;

% 2. Tail behavior: waiting-time ECDF (one matched-seed run).
% Do not duplicate it with a visually noisy overlapping histogram.
f=figure('Visible','off','Color','w','Position',[80 80 1050 565]);
cl=onCleanup(@()closeIfOpen(f)); %#ok<NASGU>
hold on;
cdfHandles=gobjects(1,n);
for j=1:n
    e=singleRuns(j).entities;
    waits=e.wait(e.accepted & isfinite(e.wait));
    [x,y]=qsim.analysis.empiricalCDF(waits);
    if ~isempty(x)
        cdfHandles(j)=stairs(x,y,'LineWidth',1.8,'Color',colors(j,:));
    else
        % Invisible empty-series legend entry; do not fabricate data.
        cdfHandles(j)=plot(NaN,NaN,'Color',colors(j,:));
    end
end
threshold=baseline.options.serviceLevelThreshold;
xline(threshold,'k--',sprintf('%.1f-min service threshold',threshold), ...
    'LabelVerticalAlignment','bottom');
xlabel('Customer waiting time (minutes)'); ylabel('Fraction waiting <= x');
title('Wait-time distribution | ONE matched-seed replication (descriptive)');
legend(cdfHandles,names,'Location','southeast'); ylim([0,1.02]); grid on;
files.waitCDF=saveFig(f,folder,'benchmarkA_wait_cdf.png');
close(f); clear cl;

% 3/4. Distinct operational questions: demand stress and staffing options.
files.loadSensitivity=plotOneSweep(loadSweep,colors,folder, ...
    'benchmarkA_load_sensitivity.png');
files.capacitySensitivity=plotOneSweep(capacitySweep,colors,folder, ...
    'benchmarkA_capacity_sensitivity.png');
end

function path=plotOneSweep(sw,colors,folder,filename)
fig=figure('Visible','off','Color','w','Position',[80 80 1130 555]);
cleanup=onCleanup(@()closeIfOpen(fig)); %#ok<NASGU>
n=numel(sw.names);
if strcmp(sw.kind,'arrivalRate')
    xx=sw.offeredLoad;
    xLabel='Offered load: arrival rate / total nominal service capacity';
    tt='Demand stress test | fixed servers';
else
    xx=sw.values(:);
    xLabel='Number of servers';
    tt='Staffing decision | fixed demand';
end
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile; hold on;
for j=1:n
    y=reshape(sw.mean(:,j,1),[],1);
    lo=reshape(sw.lower(:,j,1),[],1);
    hi=reshape(sw.upper(:,j,1),[],1);
    mask=isfinite(y)&isfinite(lo)&isfinite(hi);
    if any(mask)
        errorbar(xx(mask),y(mask),y(mask)-lo(mask),hi(mask)-y(mask), ...
            '-o','LineWidth',1.45,'Color',colors(j,:),'MarkerSize',5);
    end
end
xlabel(xLabel); ylabel('Mean waiting time (minutes)');
title([tt ' | 95% replication CI']);
legend(sw.names,'Location','best'); grid on;
nexttile; hold on;
for j=1:n
    y=reshape(sw.mean(:,j,4),[],1);
    lo=reshape(sw.lower(:,j,4),[],1);
    hi=reshape(sw.upper(:,j,4),[],1);
    mask=isfinite(y)&isfinite(lo)&isfinite(hi);
    if any(mask)
        errorbar(xx(mask),y(mask),y(mask)-lo(mask),hi(mask)-y(mask), ...
            '-o','LineWidth',1.45,'Color',colors(j,:),'MarkerSize',5);
    end
end
xlabel(xLabel); ylabel('Mean server busy fraction');
title('Resource-use trade-off | 95% replication CI');
ylim([0,1]); grid on;
path=saveFig(fig,folder,filename);
close(fig);
end

function path=saveFig(fig,folder,filename)
path=fullfile(folder,filename);
exportgraphics(fig,path,'Resolution',170);
end

function closeIfOpen(fig)
if isgraphics(fig), close(fig); end
end
