function files = plotPolicyBenchmark(result,outputFolder)
%PLOTPOLICYBENCHMARK Write three publication-readable M3 PNG figures.
% Uses base MATLAB graphics. Figures are off-screen and explicitly closed.
if nargin<2 || isempty(outputFolder)
    outputFolder=fullfile(pwd,'outputs','benchmarkA');
end
if ~exist(outputFolder,'dir'), mkdir(outputFolder); end
names={result.summary.name};
n=numel(names);
files=struct('waits','','pairedWait','','utilization','');

% Report scenario-level mean waiting time and the empirical P95, each with
% across-replication Student-t confidence intervals (NOT customer-level CI).
fig=figure('Visible','off','Color','w','Position',[80 80 1060 540]);
cleanup=onCleanup(@()closeIfOpen(fig)); %#ok<NASGU>
hold on;
keys={'meanWait','p95Wait'};
labels={'Mean wait','P95 wait'};
for m=1:2
    means=NaN(1,n); lowers=NaN(1,n); uppers=NaN(1,n);
    for j=1:n
        ci=result.summary(j).metrics.(keys{m});
        means(j)=ci.mean;
        lowers(j)=ci.lower;
        uppers(j)=ci.upper;
    end
    x=(1:n)+(m-1.5)*0.17;
    mask=isfinite(means) & isfinite(lowers) & isfinite(uppers);
    if any(mask)
        errorbar(x(mask),means(mask),means(mask)-lowers(mask), ...
            uppers(mask)-means(mask),'o','LineWidth',1.7, ...
            'MarkerSize',7,'DisplayName',labels{m});
    end
end
ax=gca;
ax.XTick=1:n;
ax.XTickLabel=names;
ax.XTickLabelRotation=10;
xlim([0.5 n+0.5]);
ylabel('Minutes');
title(sprintf('Benchmark A: waiting-time comparison (%g%% CI)', ...
    100*result.options.confidence));
legend('Location','northwest');
grid on;
files.waits=fullfile(outputFolder,'benchmarkA_waits.png');
exportgraphics(fig,files.waits,'Resolution',170);
close(fig);
clear cleanup;

% Paired contrasts, scenario minus reference. Reference scenario is omitted.
if ~isempty(result.paired)
    fig=figure('Visible','off','Color','w','Position',[80 80 980 480]);
    cleanup=onCleanup(@()closeIfOpen(fig)); %#ok<NASGU>
    k=numel(result.paired);
    contrasts={result.paired.name};
    for j=1:k
        ci=result.paired(j).difference.meanWait.ci;
        if isfinite(ci.mean) && isfinite(ci.lower) && isfinite(ci.upper)
            errorbar(j,ci.mean,ci.mean-ci.lower,ci.upper-ci.mean, ...
                'o','LineWidth',2,'MarkerSize',8);
            hold on;
        end
    end
    yline(0,'--');
    ax=gca;
    ax.XTick=1:k;
    ax.XTickLabel=contrasts;
    ax.XTickLabelRotation=10;
    xlim([0.5 k+0.5]);
    ylabel('Mean wait difference (minutes)');
    title(sprintf('Paired CRN contrasts: scenario - %s',result.paired(1).reference));
    grid on;
    files.pairedWait=fullfile(outputFolder,'benchmarkA_paired_wait.png');
    exportgraphics(fig,files.pairedWait,'Resolution',170);
    close(fig);
    clear cleanup;
end

% Show server utilization CI across independent replications.
fig=figure('Visible','off','Color','w','Position',[80 80 980 480]);
cleanup=onCleanup(@()closeIfOpen(fig)); %#ok<NASGU>
means=NaN(1,n); lows=NaN(1,n); highs=NaN(1,n);
for j=1:n
    ci=result.summary(j).metrics.meanUtilization;
    means(j)=ci.mean;
    lows(j)=ci.lower;
    highs(j)=ci.upper;
end
mask=isfinite(means) & isfinite(lows) & isfinite(highs);
if any(mask)
    errorbar(find(mask),means(mask),means(mask)-lows(mask), ...
        highs(mask)-means(mask),'o','LineWidth',1.8,'MarkerSize',8);
end
ax=gca;
ax.XTick=1:n;
ax.XTickLabel=names;
ax.XTickLabelRotation=10;
xlim([0.5 n+0.5]);
ylim([0 1]);
ylabel('Mean fraction of busy servers');
title('Benchmark A: mean server utilization');
grid on;
files.utilization=fullfile(outputFolder,'benchmarkA_utilization.png');
exportgraphics(fig,files.utilization,'Resolution',170);
end

function closeIfOpen(fig)
if isgraphics(fig), close(fig); end
end
